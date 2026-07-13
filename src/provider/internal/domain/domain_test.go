package domain

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestProgram_JSON(t *testing.T) {
	p := Program{ID: "prog-1", Name: "大数据微专业", Status: "draft", CourseIDs: []string{"cour-1", "cour-2"}}
	b, err := json.Marshal(p)
	if err != nil {
		t.Fatal(err)
	}
	var got Program
	if err := json.Unmarshal(b, &got); err != nil {
		t.Fatal(err)
	}
	if got.ID != p.ID || got.Name != p.Name || len(got.CourseIDs) != 2 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestCourse_JSON(t *testing.T) {
	c := Course{ID: "cour-1", Name: "数据工程", Status: "published"}
	b, _ := json.Marshal(c)
	var got Course
	json.Unmarshal(b, &got)
	if got.Name != "数据工程" {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestPhase_JSON(t *testing.T) {
	p := Phase{ID: "phase-1", CourseID: "cour-1", Name: "数据采集阶段", SortOrder: 1, LessonIDs: []string{"less-1", "less-2"}}
	b, _ := json.Marshal(p)
	var got Phase
	json.Unmarshal(b, &got)
	if got.Name != "数据采集阶段" || got.CourseID != "cour-1" || got.SortOrder != 1 || len(got.LessonIDs) != 2 {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestLesson_JSON(t *testing.T) {
	l := Lesson{ID: "less-1", Title: "课时1", Duration: 45, Status: "draft", StartSceneID: "scene-1"}
	b, _ := json.Marshal(l)
	var got Lesson
	json.Unmarshal(b, &got)
	if got.Title != "课时1" || got.StartSceneID != "scene-1" {
		t.Fatalf("roundtrip = %+v", got)
	}
}

func TestScene_JSON(t *testing.T) {
	sc := Scene{ID: "scene-1", LessonID: "less-1", VideoURL: "intro.mp4", Choices: []Choice{{Label: "继续", TargetSceneID: "scene-2"}}}
	b, _ := json.Marshal(sc)
	var got Scene
	json.Unmarshal(b, &got)
	if got.VideoURL != "intro.mp4" || len(got.Choices) != 1 {
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
	c := Class{ID: "class-1", Name: "浙理班级", RefName: "大数据微专业", RefType: "program", RefID: "prog-1", StartDate: "2026-09-01", EndDate: "2027-01-15", StudentCount: 30, Progress: 0.5}
	b, _ := json.Marshal(c)
	var got Class
	json.Unmarshal(b, &got)
	if got.Name != "浙理班级" || got.StudentCount != 30 || got.Progress != 0.5 {
		t.Fatalf("roundtrip = %+v", got)
	}
}
