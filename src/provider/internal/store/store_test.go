package store

import (
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

func TestCourseStore_CRUD(t *testing.T) {
	s := NewCourseStore()

	if got := s.List(); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	c := s.Create(&domain.Course{Name: "数据工程"})
	if c.ID == "" || c.Name != "数据工程" || c.Slug == "" {
		t.Fatalf("Create() = %+v", c)
	}

	s.Create(&domain.Course{Name: "数据可视化"})
	if got := s.List(); len(got) != 2 {
		t.Fatalf("List() = %d, want 2", len(got))
	}

	updated, ok := s.Update(&domain.Course{ID: c.ID, Name: "数据工程v2", Status: "published"})
	if !ok || updated.Name != "数据工程v2" || updated.Status != "published" {
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
	if l.ID == "" || l.Title != "课时1" || l.Duration != 45 || l.Slug == "" {
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

	if got := s.ListByLesson("lesson-1"); len(got) != 0 {
		t.Fatalf("List() = %d, want 0", len(got))
	}
	if _, ok := s.Get("x"); ok {
		t.Fatal("Get() nonexistent ok = true")
	}

	sc := s.Create(&domain.Scene{LessonID: "lesson-1", VideoURL: "intro.mp4", Choices: []domain.Choice{{Label: "继续", TargetSceneID: "scene-2"}}})
	if sc.ID == "" || sc.LessonID != "lesson-1" || sc.VideoURL != "intro.mp4" || len(sc.Choices) != 1 || sc.Slug == "" {
		t.Fatalf("Create() = %+v", sc)
	}

	// nil Choices → initialized to empty slice
	sc2 := s.Create(&domain.Scene{LessonID: "lesson-1", VideoURL: "outro.mp4"})
	if sc2.Choices == nil {
		t.Fatal("Create(): Choices should not be nil")
	}

	// Scene for different lesson
	s.Create(&domain.Scene{LessonID: "lesson-2", VideoURL: "other.mp4"})

	if got := s.ListByLesson("lesson-1"); len(got) != 2 {
		t.Fatalf("List(lesson-1) = %d, want 2", len(got))
	}
	if got := s.ListByLesson("lesson-2"); len(got) != 1 {
		t.Fatalf("List(lesson-2) = %d, want 1", len(got))
	}
	if got := s.ListByLesson("lesson-3"); len(got) != 0 {
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
