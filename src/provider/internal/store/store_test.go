package store

import (
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

func TestProgramStore_CRUD(t *testing.T) {
	s := NewProgramStore()

	// List empty
	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}

	// Get missing
	if _, ok := s.Get("nonexistent"); ok {
		t.Fatal("Get() ok = true, want false")
	}

	// Create
	p := s.Create(&domain.Program{Name: "大数据微专业"})
	if p.ID == "" {
		t.Fatal("Create(): id is empty")
	}
	if p.Name != "大数据微专业" {
		t.Fatalf("Create().Name = %q, want %q", p.Name, "大数据微专业")
	}
	if p.CourseIDs == nil {
		t.Fatal("Create(): CourseIDs should not be nil")
	}

	// Create with explicit course IDs
	p2 := s.Create(&domain.Program{Name: "AI微专业", CourseIDs: []string{"cour-1"}})
	if len(p2.CourseIDs) != 1 {
		t.Fatalf("Create().CourseIDs = %v, want [cour-1]", p2.CourseIDs)
	}

	// List
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}

	// Get
	got, ok := s.Get(p.ID)
	if !ok {
		t.Fatal("Get() ok = false, want true")
	}
	if got.Name != "大数据微专业" {
		t.Fatalf("Get().Name = %q, want %q", got.Name, "大数据微专业")
	}

	// Update
	updated, ok := s.Update(&domain.Program{ID: p.ID, Name: "大数据微专业 v2", Description: "updated", Status: "published", CourseIDs: []string{"cour-1", "cour-2"}})
	if !ok {
		t.Fatal("Update() ok = false, want true")
	}
	if updated.Name != "大数据微专业 v2" || updated.Description != "updated" || updated.Status != "published" || len(updated.CourseIDs) != 2 {
		t.Fatalf("Update() = %+v, doesn't match", updated)
	}

	// Update nonexistent
	if _, ok := s.Update(&domain.Program{ID: "nonexistent"}); ok {
		t.Fatal("Update() nonexistent ok = true, want false")
	}

	// Delete
	if ok := s.Delete(p.ID); !ok {
		t.Fatal("Delete() ok = false, want true")
	}
	if ok := s.Delete(p.ID); ok {
		t.Fatal("Delete() again ok = true, want false")
	}
	if _, ok := s.Get(p.ID); ok {
		t.Fatal("Get() after delete ok = true, want false")
	}
	if got := s.List(); len(got) != 1 {
		t.Fatalf("List() after delete = %d, want 1", len(got))
	}

	// Delete nonexistent
	if ok := s.Delete("nonexistent"); ok {
		t.Fatal("Delete() nonexistent ok = true, want false")
	}
}

func TestCourseStore_CRUD(t *testing.T) {
	s := NewCourseStore()

	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	c := s.Create(&domain.Course{Name: "数据工程"})
	if c.ID == "" || c.Name != "数据工程" {
		t.Fatalf("Create() = %+v", c)
	}
	if c.LessonIDs == nil {
		t.Fatal("Create(): LessonIDs should not be nil")
	}

	// Create with lesson IDs
	s.Create(&domain.Course{Name: "数据可视化", LessonIDs: []string{"less-1"}})
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}

	updated, ok := s.Update(&domain.Course{ID: c.ID, Name: "数据工程v2", Status: "published", LessonIDs: []string{"less-1"}})
	if !ok || updated.Name != "数据工程v2" || updated.Status != "published" || len(updated.LessonIDs) != 1 {
		t.Fatalf("Update() = %+v", updated)
	}
	if _, ok := s.Update(&domain.Course{ID: "x"}); ok {
		t.Fatal("Update() nonexistent ok = true")
	}

	if ok := s.Delete(c.ID); !ok {
		t.Fatal("Delete() ok = false")
	}
	if ok := s.Delete(c.ID); ok {
		t.Fatal("Delete() again ok = true")
	}
	if ok := s.Delete("x"); ok {
		t.Fatal("Delete() nonexistent ok = true")
	}
}

func TestLessonStore_CRUD(t *testing.T) {
	s := NewLessonStore()

	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	l := s.Create(&domain.Lesson{Title: "课时1", Duration: 45})
	if l.ID == "" || l.Title != "课时1" || l.Duration != 45 {
		t.Fatalf("Create() = %+v", l)
	}

	s.Create(&domain.Lesson{Title: "课时2"})
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}

	updated, ok := s.Update(&domain.Lesson{ID: l.ID, Title: "课时1更新", Description: "desc", Duration: 50, Status: "published", StartSceneID: "scene-1"})
	if !ok || updated.Title != "课时1更新" || updated.Description != "desc" || updated.Duration != 50 || updated.Status != "published" || updated.StartSceneID != "scene-1" {
		t.Fatalf("Update() = %+v", updated)
	}
	if _, ok := s.Update(&domain.Lesson{ID: "x"}); ok {
		t.Fatal("Update() nonexistent ok = true")
	}

	if ok := s.Delete(l.ID); !ok {
		t.Fatal("Delete() ok = false")
	}
	if ok := s.Delete(l.ID); ok {
		t.Fatal("Delete() again ok = true")
	}
	if ok := s.Delete("x"); ok {
		t.Fatal("Delete() nonexistent ok = true")
	}
}

func TestSceneStore_CRUD(t *testing.T) {
	s := NewSceneStore()

	if got := s.List("lesson-1"); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	sc := s.Create(&domain.Scene{LessonID: "lesson-1", VideoURL: "intro.mp4", Choices: []domain.Choice{{Label: "继续", TargetSceneID: "scene-2"}}})
	if sc.ID == "" || sc.LessonID != "lesson-1" || sc.VideoURL != "intro.mp4" || len(sc.Choices) != 1 {
		t.Fatalf("Create() = %+v", sc)
	}

	// nil Choices → initialized to empty slice
	sc2 := s.Create(&domain.Scene{LessonID: "lesson-1", VideoURL: "outro.mp4"})
	if sc2.Choices == nil {
		t.Fatal("Create(): Choices should not be nil")
	}

	// Scene for different lesson
	s.Create(&domain.Scene{LessonID: "lesson-2", VideoURL: "other.mp4"})

	if got := s.List("lesson-1"); len(got) != 2 {
		t.Fatalf("List(lesson-1) = %d, want 2", len(got))
	}
	if got := s.List("lesson-2"); len(got) != 1 {
		t.Fatalf("List(lesson-2) = %d, want 1", len(got))
	}
	if got := s.List("lesson-3"); len(got) != 0 {
		t.Fatalf("List(lesson-3) = %d, want 0", len(got))
	}

	updated, ok := s.Update(&domain.Scene{ID: sc.ID, VideoURL: "intro-v2.mp4", Choices: []domain.Choice{{Label: "跳过", TargetSceneID: "scene-3"}}})
	if !ok || updated.VideoURL != "intro-v2.mp4" || len(updated.Choices) != 1 || updated.Choices[0].Label != "跳过" {
		t.Fatalf("Update() = %+v", updated)
	}
	if _, ok := s.Update(&domain.Scene{ID: "x"}); ok {
		t.Fatal("Update() nonexistent ok = true")
	}

	if ok := s.Delete(sc.ID); !ok {
		t.Fatal("Delete() ok = false")
	}
	if ok := s.Delete(sc.ID); ok {
		t.Fatal("Delete() again ok = true")
	}
	if ok := s.Delete("x"); ok {
		t.Fatal("Delete() nonexistent ok = true")
	}
}

func TestClassStore_CRUD(t *testing.T) {
	s := NewClassStore()

	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	c := s.Create(&domain.Class{
		Name: "浙理班级", RefName: "大数据微专业", RefType: "program", RefID: "prog-1",
		StartDate: "2026-09-01", EndDate: "2027-01-15", StudentCount: 30,
	})
	if c.ID == "" || c.Name != "浙理班级" || c.StudentCount != 30 {
		t.Fatalf("Create() = %+v", c)
	}

	s.Create(&domain.Class{Name: "杭电班级", RefName: "AI微专业", RefType: "program", RefID: "prog-2", StartDate: "2026-09-01", EndDate: "2027-01-15"})
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}

	updated, ok := s.Update(&domain.Class{ID: c.ID, Name: "浙理班级v2", RefName: "大数据微专业v2", RefType: "course", RefID: "cour-1", Status: "active", StartDate: "2026-09-15", EndDate: "2027-02-01", StudentCount: 35, Progress: 0.5})
	if !ok || updated.Name != "浙理班级v2" || updated.RefType != "course" || updated.StudentCount != 35 || updated.Progress != 0.5 {
		t.Fatalf("Update() = %+v", updated)
	}
	if _, ok := s.Update(&domain.Class{ID: "x"}); ok {
		t.Fatal("Update() nonexistent ok = true")
	}

	if ok := s.Delete(c.ID); !ok {
		t.Fatal("Delete() ok = false")
	}
	if ok := s.Delete(c.ID); ok {
		t.Fatal("Delete() again ok = true")
	}
	if ok := s.Delete("x"); ok {
		t.Fatal("Delete() nonexistent ok = true")
	}
}
