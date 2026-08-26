package domain

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestCourse_JSON(t *testing.T) {
	c := Course{ID: "cour-1", Name: "数据工程", Slug: "slug-cour-1", Status: "published"}
	b, _ := json.Marshal(c)
	var got Course
	json.Unmarshal(b, &got)
	if got.Name != "数据工程" || got.Slug != "slug-cour-1" {
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
	sc := Scene{ID: "scene-1", LessonID: "less-1", Slug: "slug-scene-1", VideoURL: "intro.mp4", Choices: []Choice{{Label: "继续", TargetSceneID: "scene-2"}}, Criteria: []string{"cri-1"}}
	b, _ := json.Marshal(sc)
	var got Scene
	json.Unmarshal(b, &got)
	if got.VideoURL != "intro.mp4" || got.Slug != "slug-scene-1" || len(got.Choices) != 1 {
		t.Fatalf("roundtrip = %+v", got)
	}
	if len(got.Criteria) != 1 || got.Criteria[0] != "cri-1" {
		t.Fatalf("criteria roundtrip = %+v", got.Criteria)
	}
}

func TestLesson_Criteria(t *testing.T) {
	l := Lesson{ID: "less-1", Title: "课时1", CourseID: "cour-1", Criteria: []string{"cri-1", "cri-2"}}
	b, _ := json.Marshal(l)
	var got Lesson
	json.Unmarshal(b, &got)
	if got.CourseID != "cour-1" || len(got.Criteria) != 2 || got.Criteria[1] != "cri-2" {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestCriterion_JSON(t *testing.T) {
	c := Criterion{ID: "cri-1", LessonID: "less-1", Title: "会连接 Zed", Description: "Zed 已启动且主题配置生效"}
	b, _ := json.Marshal(c)
	var got Criterion
	json.Unmarshal(b, &got)
	if got.ID != "cri-1" || got.LessonID != "less-1" || got.Title != "会连接 Zed" || got.Description != "Zed 已启动且主题配置生效" {
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
