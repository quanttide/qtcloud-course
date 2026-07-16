package domain

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestProgram_JSON(t *testing.T) {
	p := Program{ID: "prog-1", Name: "大数据微专业", Slug: "slug-prog-1", Status: "draft", CourseIDs: []string{"cour-1", "cour-2"}}
	b, err := json.Marshal(p)
	if err != nil {
		t.Fatal(err)
	}
	var got Program
	if err := json.Unmarshal(b, &got); err != nil {
		t.Fatal(err)
	}
	if got.ID != p.ID || got.Name != p.Name || got.Slug != "slug-prog-1" || len(got.CourseIDs) != 2 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestCourse_JSON(t *testing.T) {
	c := Course{ID: "cour-1", Name: "数据工程", Slug: "slug-cour-1", Status: "published"}
	b, _ := json.Marshal(c)
	var got Course
	json.Unmarshal(b, &got)
	if got.Name != "数据工程" || got.Slug != "slug-cour-1" {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestPhase_JSON(t *testing.T) {
	p := Phase{ID: "phase-1", CourseID: "cour-1", Name: "数据采集阶段", Slug: "slug-phase-1", SortOrder: 1, LessonIDs: []string{"less-1", "less-2"}}
	b, _ := json.Marshal(p)
	var got Phase
	json.Unmarshal(b, &got)
	if got.Name != "数据采集阶段" || got.CourseID != "cour-1" || got.Slug != "slug-phase-1" || got.SortOrder != 1 || len(got.LessonIDs) != 2 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestLesson_JSON(t *testing.T) {
	l := Lesson{ID: "less-1", Title: "课时1", Slug: "slug-less-1", Duration: 45, Status: "draft", StartSceneID: "scene-1"}
	b, _ := json.Marshal(l)
	var got Lesson
	json.Unmarshal(b, &got)
	if got.Title != "课时1" || got.Slug != "slug-less-1" || got.StartSceneID != "scene-1" {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestScene_JSON(t *testing.T) {
	sc := Scene{ID: "scene-1", LessonID: "less-1", Slug: "slug-scene-1", VideoURL: "intro.mp4", Choices: []Choice{{Label: "继续", TargetSceneID: "scene-2"}}}
	b, _ := json.Marshal(sc)
	var got Scene
	json.Unmarshal(b, &got)
	if got.VideoURL != "intro.mp4" || got.Slug != "slug-scene-1" || len(got.Choices) != 1 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestScene_EmptyChoices(t *testing.T) {
	sc := Scene{ID: "scene-1", LessonID: "less-1", VideoURL: "outro.mp4", Choices: []Choice{}}
	b, _ := json.Marshal(sc)
	if !strings.Contains(string(b), `"choices":[]`) {
		t.Fatalf("empty choices should serialize as [], got %s", string(b))
	}
}

func TestClass_JSON(t *testing.T) {
	c := Class{ID: "class-1", Name: "浙理班级", Slug: "slug-class-1", RefName: "大数据微专业", RefType: "program", RefID: "prog-1", StartDate: "2026-09-01", EndDate: "2027-01-15", StudentCount: 30, Progress: 0.5}
	b, _ := json.Marshal(c)
	var got Class
	json.Unmarshal(b, &got)
	if got.Name != "浙理班级" || got.Slug != "slug-class-1" || got.StudentCount != 30 || got.Progress != 0.5 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestMakeSlug_ASCII(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		prefix string
		want   string
	}{
		{"simple", "Hello World", "h-1", "hello-world"},
		{"mixed case", "Go Programming 101", "gp-1", "go-programming-101"},
		{"dash preserved", "user-guide-v2", "ug-2", "user-guide-v2"},
		{"underscore", "my_var_name", "mvn-1", "my-var-name"},
		{"special chars", "data@science#101", "ds-1", "datascience101"},
		{"trailing dash", "hello- ", "h-2", "hello"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := MakeSlug(tt.input, tt.prefix)
			if got != tt.want {
				t.Errorf("MakeSlug(%q, %q) = %q, want %q", tt.input, tt.prefix, got, tt.want)
			}
		})
	}
}

func TestMakeSlug_Chinese(t *testing.T) {
	got := MakeSlug("大数据微专业", "prog-1")
	if got != "slug-prog-1" {
		t.Errorf("MakeSlug(Chinese) = %q, want %q", got, "slug-prog-1")
	}
}

func TestMakeSlug_Empty(t *testing.T) {
	got := MakeSlug("", "e-1")
	if got != "slug-e-1" {
		t.Errorf("MakeSlug(empty) = %q, want %q", got, "slug-e-1")
	}
}
