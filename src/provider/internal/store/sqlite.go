// SQLite 持久化存储：JSON 列存储 + 全量快照。
// 数据量小（教程级），每次写操作后全量序列化落盘，读走内存——简单可靠，关闭不丢数据。

package store

import (
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

const sqliteSchema = `
CREATE TABLE IF NOT EXISTS resources (
	table_name TEXT NOT NULL,
	id         TEXT NOT NULL,
	data       TEXT NOT NULL,
	PRIMARY KEY (table_name, id)
);`

// SQLiteStore 是持久化的泛型存储：嵌入 BaseStore（内存读写），写后快照落盘。
type SQLiteStore[T any] struct {
	*BaseStore[T]
	db    *sql.DB
	table string
}

// NewSQLiteStore 创建持久化存储（table 如 "programs"）。
func NewSQLiteStore[T any](db *sql.DB, idPrefix, table string) (*SQLiteStore[T], error) {
	if _, err := db.Exec(sqliteSchema); err != nil {
		return nil, fmt.Errorf("sqlite init: %w", err)
	}
	s := &SQLiteStore[T]{BaseStore: NewBaseStore[T](idPrefix), db: db, table: table}
	if err := s.restore(); err != nil {
		return nil, err
	}
	return s, nil
}

// restore 启动时从 SQLite 加载全部记录到内存。
func (s *SQLiteStore[T]) restore() error {
	rows, err := s.db.Query("SELECT id, data FROM resources WHERE table_name = ?", s.table)
	if err != nil {
		return fmt.Errorf("sqlite restore: %w", err)
	}
	defer rows.Close()
	s.mu.Lock()
	defer s.mu.Unlock()
	for rows.Next() {
		var id, raw string
		if err := rows.Scan(&id, &raw); err != nil {
			return err
		}
		var v T
		if err := json.Unmarshal([]byte(raw), &v); err != nil {
			return fmt.Errorf("sqlite restore %s/%s: %w", s.table, id, err)
		}
		s.data[id] = &v
		// 恢复自增序列（id 形如 "prog-12"）
		var n int
		if _, err := fmt.Sscanf(id, "%*[^-]-%d", &n); err == nil && n >= s.seq {
			s.seq = n + 1
		}
	}
	return rows.Err()
}

// snapshot 写后全量落盘。
func (s *SQLiteStore[T]) snapshot() error {
	s.mu.RLock()
	entries := make(map[string]*T, len(s.data))
	for k, v := range s.data {
		entries[k] = v
	}
	s.mu.RUnlock()

	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec("DELETE FROM resources WHERE table_name = ?", s.table); err != nil {
		return err
	}
	stmt, err := tx.Prepare("INSERT INTO resources (table_name, id, data) VALUES (?, ?, ?)")
	if err != nil {
		return err
	}
	defer stmt.Close()
	for id, v := range entries {
		raw, err := json.Marshal(v)
		if err != nil {
			return err
		}
		if _, err := stmt.Exec(s.table, id, string(raw)); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// Create 覆盖 BaseStore 的写入并落盘。
func (s *SQLiteStore[T]) Create(v *T) *T {
	created := s.BaseStore.create(v)
	if err := s.snapshot(); err != nil {
		// 落盘失败回滚内存写入，保持一致性
		s.mu.Lock()
		delete(s.data, idOf(created))
		s.mu.Unlock()
	}
	return created
}

// Update 覆盖写并落盘。
func (s *SQLiteStore[T]) Update(v *T) (*T, bool) {
	updated, ok := s.BaseStore.update(v)
	if ok {
		if err := s.snapshot(); err != nil {
			// 落盘失败：内存保留（下次写会重试全量快照），记录错误由上层处理
			return updated, false
		}
	}
	return updated, ok
}

// Delete 覆盖删除并落盘。
func (s *SQLiteStore[T]) Delete(id string) bool {
	deleted := s.BaseStore.delete(id)
	if deleted {
		if err := s.snapshot(); err != nil {
			return false
		}
	}
	return deleted
}

// ── 具体类型（持久化版） ──

// NewSQLiteProgramStore 持久化 Program 存储。
func NewSQLiteProgramStore(db *sql.DB) (*SQLiteStore[domain.Program], error) {
	return NewSQLiteStore[domain.Program](db, "prog", "programs")
}

// NewSQLiteCourseStore 持久化 Course 存储。
func NewSQLiteCourseStore(db *sql.DB) (*SQLiteStore[domain.Course], error) {
	return NewSQLiteStore[domain.Course](db, "cour", "courses")
}

// NewSQLitePhaseStore 持久化 Phase 存储。
func NewSQLitePhaseStore(db *sql.DB) (*SQLiteStore[domain.Phase], error) {
	return NewSQLiteStore[domain.Phase](db, "phas", "phases")
}

// NewSQLiteLessonStore 持久化 Lesson 存储。
func NewSQLiteLessonStore(db *sql.DB) (*SQLiteStore[domain.Lesson], error) {
	return NewSQLiteStore[domain.Lesson](db, "less", "lessons")
}

// NewSQLiteSceneStore 持久化 Scene 存储。
func NewSQLiteSceneStore(db *sql.DB) (*SQLiteStore[domain.Scene], error) {
	return NewSQLiteStore[domain.Scene](db, "scen", "scenes")
}
