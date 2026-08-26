// 对象存储持久化存储：每表一个对象（{table}.json），保存全量实体列表。
// 懒加载：首次操作时从对象存储拉取到内存缓存（之后读写走内存）；写后全量覆盖回对象存储（原子写）。
// 数据量小（教程级），简单可靠——生产（FC 容器）用 OSS，容器回收数据仍在（解决 FC 无持久化问题）。

package store

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sort"
	"strconv"
	"strings"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// OSSStore 是对象存储持久化的泛型存储：嵌入 BaseStore（内存读写）+ 懒加载 + 写后快照。
// 与 SQLiteStore 接口一致（List/Get/Create/Update/Delete/NameExists/ListWhere/SetID）。
type OSSStore[T any] struct {
	*BaseStore[T]
	backend Store
	table   string // 如 "programs" → 对象 "programs.json"
	loaded  bool   // 是否已从后端加载
	loadErr error  // 最近一次加载错误（失败后下次操作重试）
}

// NewOSSStore 创建对象存储持久化 store（table 如 "programs"）。
// 懒加载：不立即访问后端，首次操作时拉取。
func NewOSSStore[T any](backend Store, idPrefix, table string) (*OSSStore[T], error) {
	if backend == nil {
		return nil, fmt.Errorf("oss store %s: backend is nil", table)
	}
	return &OSSStore[T]{
		BaseStore: NewBaseStore[T](idPrefix),
		backend:   backend,
		table:     table,
	}, nil
}

// key 返回该表对应的对象名。
func (s *OSSStore[T]) key() string {
	return s.table + ".json"
}

// ensureLoaded 懒加载：首次操作时从后端拉取全量实体到内存。
// 失败时缓存错误并保持未加载（下次操作重试），避免覆盖已有数据。
func (s *OSSStore[T]) ensureLoaded() error {
	s.mu.RLock()
	loaded := s.loaded
	s.mu.RUnlock()
	if loaded {
		return nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.loaded {
		return nil
	}
	if err := s.load(); err != nil {
		s.loadErr = err
		return err
	}
	s.loaded = true
	s.loadErr = nil
	return nil
}

// load 从后端读取 {table}.json 并填充内存（恢复自增序列）。
func (s *OSSStore[T]) load() error {
	raw, err := s.backend.Get(context.Background(), s.key())
	if err != nil {
		if err == ErrNotFound {
			// 对象尚未创建（首次写入）：按空表处理
			return nil
		}
		return fmt.Errorf("oss store %s: load: %w", s.table, err)
	}
	var items []T
	if err := json.Unmarshal(raw, &items); err != nil {
		return fmt.Errorf("oss store %s: parse %s: %w", s.table, s.key(), err)
	}
	for i := range items {
		v := &items[i]
		id := idOf(v)
		if id == "" {
			return fmt.Errorf("oss store %s: entity missing id", s.table)
		}
		s.data[id] = v
		// 恢复自增序列（id 形如 "prog-12"）
		if n, ok := numericSuffix(id); ok && n >= s.seq {
			s.seq = n + 1
		}
	}
	return nil
}

// snapshot 写后全量覆盖回对象存储：按 ID 排序保证确定性（diff 友好）。
func (s *OSSStore[T]) snapshot() error {
	s.mu.RLock()
	entries := make([]*T, 0, len(s.data))
	for _, v := range s.data {
		entries = append(entries, v)
	}
	s.mu.RUnlock()
	sort.Slice(entries, func(i, j int) bool {
		return idOf(entries[i]) < idOf(entries[j])
	})
	raw, err := json.Marshal(entries)
	if err != nil {
		return fmt.Errorf("oss store %s: marshal: %w", s.table, err)
	}
	return s.backend.Put(context.Background(), s.key(), raw)
}

// ── 读操作（懒加载失败时返回空/不存在，下次操作重试） ──

// List 返回全部实体。
func (s *OSSStore[T]) List() []*T {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: load failed, list empty: %v", s.table, err)
		return []*T{}
	}
	return s.BaseStore.List()
}

// Get 按 ID 查找实体。
func (s *OSSStore[T]) Get(id string) (*T, bool) {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: load failed: %v", s.table, err)
		return nil, false
	}
	return s.BaseStore.Get(id)
}

// NameExists 检查 name 是否已被占用。
func (s *OSSStore[T]) NameExists(name string, getName func(*T) string) bool {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: load failed: %v", s.table, err)
		return false
	}
	return s.BaseStore.NameExists(name, getName)
}

// ListWhere 按 JSON 字段过滤（如 ListWhere("courseId", "cour-1")）。
func (s *OSSStore[T]) ListWhere(field, value string) []*T {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: load failed: %v", s.table, err)
		return []*T{}
	}
	return s.BaseStore.ListWhere(field, value)
}

// ── 写操作（懒加载失败时拒绝写入，避免覆盖已有数据） ──

// Create 创建并写回对象存储。
func (s *OSSStore[T]) Create(v *T) *T {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: create rejected (load failed): %v", s.table, err)
		return nil
	}
	created := s.BaseStore.create(v)
	if err := s.snapshot(); err != nil {
		// 写回失败：回滚内存写入，保持一致性
		s.mu.Lock()
		delete(s.data, idOf(created))
		s.mu.Unlock()
		log.Printf("oss store %s: create failed: %v", s.table, err)
		return nil
	}
	return created
}

// Update 覆盖写并写回对象存储。
func (s *OSSStore[T]) Update(v *T) (*T, bool) {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: update rejected (load failed): %v", s.table, err)
		return nil, false
	}
	updated, ok := s.BaseStore.update(v)
	if ok {
		if err := s.snapshot(); err != nil {
			// 写回失败：内存保留（下次写会重试全量快照），记录错误由上层处理
			log.Printf("oss store %s: update snapshot failed: %v", s.table, err)
			return updated, false
		}
	}
	return updated, ok
}

// Delete 删除并写回对象存储。
func (s *OSSStore[T]) Delete(id string) bool {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: delete rejected (load failed): %v", s.table, err)
		return false
	}
	deleted := s.BaseStore.delete(id)
	if deleted {
		if err := s.snapshot(); err != nil {
			log.Printf("oss store %s: delete snapshot failed: %v", s.table, err)
			return false
		}
	}
	return deleted
}

// SetID 改写实体 ID 并写回对象存储（seed 固定 ID 用，如生产实习课程 id=prod）。
func (s *OSSStore[T]) SetID(v *T, newID string) {
	if err := s.ensureLoaded(); err != nil {
		log.Printf("oss store %s: SetID rejected (load failed): %v", s.table, err)
		return
	}
	s.BaseStore.SetID(v, newID)
	if err := s.snapshot(); err != nil {
		log.Printf("oss store %s: SetID snapshot failed: %v", s.table, err)
	}
}

// ── 具体类型（对象存储持久化版） ──

// NewOSSProgramStore 对象存储持久化 Program 存储。
func NewOSSProgramStore(backend Store) (*OSSStore[domain.Program], error) {
	return NewOSSStore[domain.Program](backend, "prog", "programs")
}

// NewOSSCourseStore 对象存储持久化 Course 存储。
func NewOSSCourseStore(backend Store) (*OSSStore[domain.Course], error) {
	return NewOSSStore[domain.Course](backend, "cour", "courses")
}

// NewOSSPhaseStore 对象存储持久化 Phase 存储。
func NewOSSPhaseStore(backend Store) (*OSSStore[domain.Phase], error) {
	return NewOSSStore[domain.Phase](backend, "phas", "phases")
}

// NewOSSLessonStore 对象存储持久化 Lesson 存储。
func NewOSSLessonStore(backend Store) (*OSSStore[domain.Lesson], error) {
	return NewOSSStore[domain.Lesson](backend, "less", "lessons")
}

// NewOSSSceneStore 对象存储持久化 Scene 存储。
func NewOSSSceneStore(backend Store) (*OSSStore[domain.Scene], error) {
	return NewOSSStore[domain.Scene](backend, "scen", "scenes")
}

// numericSuffix 提取 ID 的数字后缀（如 "prog-12" → 12）。
func numericSuffix(id string) (int, bool) {
	idx := strings.LastIndex(id, "-")
	if idx < 0 || idx == len(id)-1 {
		return 0, false
	}
	n, err := strconv.Atoi(id[idx+1:])
	if err != nil {
		return 0, false
	}
	return n, true
}
