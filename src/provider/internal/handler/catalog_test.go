package handler

// 公开课程目录 API 测试：/v1/courses 列表/详情/player。

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// setupCatalogMux 内存 store + 公开路由（与 registerPublicAPI 对齐）。
func setupCatalogMux() (*http.ServeMux, *store.ProgramStore, *store.CourseStore, *store.PhaseStore, *store.LessonStore, *store.SceneStore) {
	ps := store.NewProgramStore()
	cs := store.NewCourseStore()
	phs := store.NewPhaseStore()
	ls := store.NewLessonStore()
	ss := store.NewSceneStore()

	catalog := NewCatalogHandler(ps, cs, phs, ls)
	player := NewPlayerHandler(ps, cs, phs, ls, ss)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/courses", catalog.List)
	mux.HandleFunc("GET /v1/courses/{id}", catalog.Get)
	mux.HandleFunc("GET /v1/courses/{id}/player", player.GetByCourse)
	return mux, ps, cs, phs, ls, ss
}

// seedCatalogData 构造 5 门课（2 published + 2 draft）+ 1 个生产实习形态课程。
func seedCatalogData(ps *store.ProgramStore, cs *store.CourseStore, phs *store.PhaseStore, ls *store.LessonStore) {
	prog := ps.Create(&domain.Program{Name: "quanttide-micro", Status: "published"})
	// 生产实习（published）+ 1 门暂未开放（draft）
	prod := cs.Create(&domain.Course{Name: "生产实习", Description: "走进真实业务", Status: "published"})
	cs.SetID(prod, "prod")
	locked := cs.Create(&domain.Course{Name: "知识工作", Description: "方法课", Status: "draft"})
	cs.SetID(locked, "knowledge-work")
	prog.CourseIDs = []string{prod.ID, locked.ID}
	ps.Update(prog)

	// 生产实习 2 个模块 + 课时
	phase1 := phs.Create(&domain.Phase{CourseID: prod.ID, Name: "量潮是谁", SortOrder: 1})
	l1 := ls.Create(&domain.Lesson{Title: "创立故事", Duration: 10, Status: "published"})
	phase1.LessonIDs = []string{l1.ID}
	phs.Update(phase1)
}

func TestCatalogList(t *testing.T) {
	mux, ps, cs, phs, ls, _ := setupCatalogMux()
	seedCatalogData(ps, cs, phs, ls)

	req := httptest.NewRequest("GET", "/v1/courses", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d", w.Code)
	}
	var body struct {
		Courses []CatalogCourse `json:"courses"`
	}
	json.NewDecoder(w.Body).Decode(&body)
	if len(body.Courses) != 2 {
		t.Fatalf("courses = %d, want 2", len(body.Courses))
	}
	// 顺序：knowledge-work ① → prod ⑤
	if body.Courses[0].ID != "knowledge-work" || body.Courses[1].ID != "prod" {
		t.Errorf("order = %s,%s", body.Courses[0].ID, body.Courses[1].ID)
	}
	if body.Courses[0].Status != "locked" {
		t.Errorf("knowledge-work status = %s, want locked", body.Courses[0].Status)
	}
	if body.Courses[1].Status != "open" {
		t.Errorf("prod status = %s, want open", body.Courses[1].Status)
	}
	if body.Courses[1].Icon != "🏭" || body.Courses[1].Badge != "生产实习 · 微型创业" {
		t.Errorf("prod display = %s/%s", body.Courses[1].Icon, body.Courses[1].Badge)
	}
}

func TestCatalogGet(t *testing.T) {
	mux, ps, cs, phs, ls, _ := setupCatalogMux()
	seedCatalogData(ps, cs, phs, ls)

	req := httptest.NewRequest("GET", "/v1/courses/prod", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, body=%s", w.Code, w.Body.String())
	}
	var course CatalogCourse
	json.NewDecoder(w.Body).Decode(&course)
	if len(course.Stages) != 1 || course.Stages[0].Name != "量潮是谁" {
		t.Errorf("stages = %+v", course.Stages)
	}
	if len(course.Stages[0].Lessons) != 1 || course.Stages[0].Lessons[0].Duration == "" {
		t.Errorf("lessons = %+v", course.Stages[0].Lessons)
	}

	// 不存在的课程 → 404
	req2 := httptest.NewRequest("GET", "/v1/courses/nope", nil)
	w2 := httptest.NewRecorder()
	mux.ServeHTTP(w2, req2)
	if w2.Code != http.StatusNotFound {
		t.Errorf("missing course status = %d, want 404", w2.Code)
	}
}

func TestCatalogPlayer(t *testing.T) {
	mux, ps, cs, phs, ls, ss := setupCatalogMux()
	seedCatalogData(ps, cs, phs, ls)
	// 给课时补一个场景（播放数据源）
	lesson := ls.List()[0]
	ss.Create(&domain.Scene{LessonID: lesson.ID, Title: "创立故事", Slug: "intro", VerifyTip: "阅读内容"})

	req := httptest.NewRequest("GET", "/v1/courses/prod/player", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, body=%s", w.Code, w.Body.String())
	}
	var data PlayerData
	json.NewDecoder(w.Body).Decode(&data)
	if data.Title != "生产实习" {
		t.Errorf("title = %s", data.Title)
	}
	if len(data.PathSteps) != 1 || len(data.Segments) != 1 {
		t.Errorf("pathSteps=%d segments=%d, want 1/1", len(data.PathSteps), len(data.Segments))
	}
}
