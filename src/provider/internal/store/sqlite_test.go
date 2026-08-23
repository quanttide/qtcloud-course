package store

// SQLite 持久化测试：写入 → 重开存储 → 数据仍在。

import (
	"database/sql"
	"path/filepath"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	_ "modernc.org/sqlite"
)

func TestSQLiteProgramStore_Persists(t *testing.T) {
	path := filepath.Join(t.TempDir(), "test.db")
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	s, err := NewSQLiteProgramStore(db)
	if err != nil {
		t.Fatal(err)
	}
	created := s.Create(&domain.Program{Name: "vibe-coding"})
	if created.ID == "" {
		t.Fatal("create should assign id")
	}

	// 重开（模拟重启）：restore 从 SQLite 加载
	s2, err := NewSQLiteProgramStore(db)
	if err != nil {
		t.Fatal(err)
	}
	got, ok := s2.Get(created.ID)
	if !ok {
		t.Fatal("重启后数据丢失")
	}
	if got.Name != "vibe-coding" {
		t.Fatalf("name = %q, want vibe-coding", got.Name)
	}

	// Update 持久化
	if _, ok := s2.Update(&domain.Program{ID: created.ID, Name: "vibe-coding-v2"}); !ok {
		t.Fatal("update failed")
	}
	s3, _ := NewSQLiteProgramStore(db)
	got2, _ := s3.Get(created.ID)
	if got2.Name != "vibe-coding-v2" {
		t.Fatalf("update 未持久化: %q", got2.Name)
	}

	// Delete 持久化
	if !s3.Delete(created.ID) {
		t.Fatal("delete failed")
	}
	s4, _ := NewSQLiteProgramStore(db)
	if _, ok := s4.Get(created.ID); ok {
		t.Fatal("delete 未持久化")
	}
}

func TestSQLiteStore_RestoresSequence(t *testing.T) {
	path := filepath.Join(t.TempDir(), "seq.db")
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	s, err := NewSQLiteProgramStore(db)
	if err != nil {
		t.Fatal(err)
	}
	first := s.Create(&domain.Program{Name: "first"})
	if first.ID != "prog-1" {
		t.Fatalf("first ID = %q, want prog-1", first.ID)
	}

	reopened, err := NewSQLiteProgramStore(db)
	if err != nil {
		t.Fatal(err)
	}
	second := reopened.Create(&domain.Program{Name: "second"})
	if second.ID != "prog-2" {
		t.Fatalf("second ID = %q, want prog-2", second.ID)
	}
	if got, ok := reopened.Get(first.ID); !ok || got.Name != "first" {
		t.Fatalf("first record overwritten or missing: %#v ok=%v", got, ok)
	}
}

func TestSQLiteSceneStore_ListWhere(t *testing.T) {
	path := filepath.Join(t.TempDir(), "scene.db")
	db, _ := sql.Open("sqlite", path)
	defer db.Close()

	s, _ := NewSQLiteSceneStore(db)
	s.Create(&domain.Scene{LessonID: "less-1", Title: "s1"})
	s.Create(&domain.Scene{LessonID: "less-1", Title: "s2"})
	s.Create(&domain.Scene{LessonID: "less-2", Title: "s3"})

	got := s.ListWhere("lessonId", "less-1")
	if len(got) != 2 {
		t.Fatalf("ListWhere = %d, want 2", len(got))
	}
}
