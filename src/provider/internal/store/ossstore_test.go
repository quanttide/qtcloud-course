package store

// OSSStore 持久化测试：每表一个对象（{table}.json），懒加载 + 写后全量覆盖。
// 覆盖：List/Get/Create/Update/Delete/NameExists/ListWhere/SetID + 重启恢复（seq 续号）。

import (
	"encoding/json"
	"sync"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// newMockBackend 创建指向 mock OSS 的 Store 后端。
func newMockBackend(t *testing.T) (Store, *sync.Map) {
	t.Helper()
	srv, objects := mockOSSServer(t)
	st, err := NewOSS(OSSConfig{
		Endpoint:        srv.URL,
		Bucket:          "bucket",
		AccessKeyID:     "AKID",
		AccessKeySecret: "SECRET",
	})
	if err != nil {
		t.Fatal(err)
	}
	return st, objects
}

func TestOSSStore_CRUD(t *testing.T) {
	backend, _ := newMockBackend(t)
	s, err := NewOSSCourseStore(backend)
	if err != nil {
		t.Fatal(err)
	}

	// 首次操作触发懒加载（对象不存在 → 空表）
	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}
	if _, ok := s.Get("nonexistent"); ok {
		t.Fatal("Get() ok = true, want false")
	}

	// Create
	p := s.Create(&domain.Course{Name: "大数据微专业"})
	if p.ID == "" || p.Name != "大数据微专业" {
		t.Fatalf("Create() = %+v", p)
	}
	if p.ID != "cour-1" {
		t.Fatalf("Create().ID = %q, want cour-1", p.ID)
	}

	p2 := s.Create(&domain.Course{Name: "AI微专业"})
	if p2.ID != "cour-2" {
		t.Fatalf("second Create().ID = %q, want cour-2", p2.ID)
	}

	// 写后对象已同步到后端
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}
	got, ok := s.Get(p.ID)
	if !ok || got.Name != "大数据微专业" {
		t.Fatalf("Get() = %+v ok=%v", got, ok)
	}

	// Update
	updated, ok := s.Update(&domain.Course{ID: p.ID, Name: "大数据微专业 v2", Description: "updated", Status: "published"})
	if !ok || updated.Name != "大数据微专业 v2" || updated.Description != "updated" {
		t.Fatalf("Update() = %+v ok=%v", updated, ok)
	}
	if _, ok := s.Update(&domain.Course{ID: "nonexistent"}); ok {
		t.Fatal("Update() nonexistent ok = true, want false")
	}

	// NameExists
	if !s.NameExists("大数据微专业 v2", func(p *domain.Course) string { return p.Name }) {
		t.Fatal("NameExists() = false, want true")
	}
	if s.NameExists("no-such-name", func(p *domain.Course) string { return p.Name }) {
		t.Fatal("NameExists() = true, want false")
	}

	// Delete
	if ok := s.Delete(p.ID); !ok {
		t.Fatal("Delete() ok = false, want true")
	}
	if ok := s.Delete(p.ID); ok {
		t.Fatal("Delete() again ok = true, want false")
	}
	if ok := s.Delete("nonexistent"); ok {
		t.Fatal("Delete() nonexistent ok = true, want false")
	}
	if got := s.List(); len(got) != 1 {
		t.Fatalf("List() after delete = %d, want 1", len(got))
	}
}

func TestOSSStore_Persists(t *testing.T) {
	backend, objects := newMockBackend(t)

	// 第一次"运行"：写入
	s1, _ := NewOSSCourseStore(backend)
	created := s1.Create(&domain.Course{Name: "vibe-coding"})
	if created.ID != "cour-1" {
		t.Fatalf("ID = %q, want cour-1", created.ID)
	}

	// 对象 {table}.json 已落到后端（全量实体列表）
	if _, ok := objects.Load("courses.json"); !ok {
		t.Fatal("programs.json 未写入 mock OSS")
	}

	// 模拟重启：新 store 实例懒加载恢复
	s2, _ := NewOSSCourseStore(backend)
	got, ok := s2.Get(created.ID)
	if !ok {
		t.Fatal("重启后数据丢失")
	}
	if got.Name != "vibe-coding" {
		t.Fatalf("name = %q, want vibe-coding", got.Name)
	}

	// seq 恢复：重启后 Create 续号
	next := s2.Create(&domain.Course{Name: "second"})
	if next.ID != "cour-2" {
		t.Fatalf("重启后 Create().ID = %q, want cour-2", next.ID)
	}
	if got2, ok := s2.Get(created.ID); !ok || got2.Name != "vibe-coding" {
		t.Fatalf("first record overwritten or missing: %#v ok=%v", got2, ok)
	}

	// Update 持久化
	if _, ok := s2.Update(&domain.Course{ID: created.ID, Name: "vibe-coding-v2"}); !ok {
		t.Fatal("update failed")
	}
	s3, _ := NewOSSCourseStore(backend)
	got3, _ := s3.Get(created.ID)
	if got3.Name != "vibe-coding-v2" {
		t.Fatalf("update 未持久化: %q", got3.Name)
	}

	// Delete 持久化
	if !s3.Delete(created.ID) {
		t.Fatal("delete failed")
	}
	s4, _ := NewOSSCourseStore(backend)
	if _, ok := s4.Get(created.ID); ok {
		t.Fatal("delete 未持久化")
	}
}

func TestOSSStore_ListWhereAndSetID(t *testing.T) {
	backend, _ := newMockBackend(t)
	s, _ := NewOSSSceneStore(backend)

	s.Create(&domain.Scene{LessonID: "less-1", Title: "s1"})
	s.Create(&domain.Scene{LessonID: "less-1", Title: "s2"})
	s.Create(&domain.Scene{LessonID: "less-2", Title: "s3"})

	got := s.ListWhere("lessonId", "less-1")
	if len(got) != 2 {
		t.Fatalf("ListWhere(lessonId, less-1) = %d, want 2", len(got))
	}

	// SetID：改写 ID 并持久化（seed 固定 ID 用）
	c, _ := NewOSSCourseStore(backend)
	course := c.Create(&domain.Course{Name: "生产实习"})
	c.SetID(course, "prod")
	if course.ID != "prod" {
		t.Fatalf("SetID() ID = %q, want prod", course.ID)
	}

	reopened, _ := NewOSSCourseStore(backend)
	got2, ok := reopened.Get("prod")
	if !ok {
		t.Fatal("SetID 未持久化")
	}
	if got2.Name != "生产实习" {
		t.Fatalf("name = %q", got2.Name)
	}
	// 旧 ID 已迁移
	if _, ok := reopened.Get(course.ID); ok && course.ID != "prod" {
		t.Fatal("旧 ID 仍存在")
	}
}

func TestOSSStore_SnapshotFormat(t *testing.T) {
	// 快照为全量实体列表（JSON 数组，按 ID 排序保证确定性）。
	backend, objects := newMockBackend(t)
	s, _ := NewOSSCourseStore(backend)
	s.Create(&domain.Course{Name: "second"})
	s.Create(&domain.Course{Name: "first"})

	raw, ok := objects.Load("courses.json")
	if !ok {
		t.Fatal("programs.json 未写入")
	}
	var items []map[string]any
	if err := json.Unmarshal(raw.([]byte), &items); err != nil {
		t.Fatalf("parse snapshot: %v", err)
	}
	if len(items) != 2 {
		t.Fatalf("snapshot len = %d, want 2", len(items))
	}
	// 按 ID 排序（cour-1 在 cour-2 前）
	if items[0]["id"] != "cour-1" || items[1]["id"] != "cour-2" {
		t.Fatalf("snapshot order = %v, %v", items[0]["id"], items[1]["id"])
	}
}
