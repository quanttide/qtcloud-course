package handler

// Criterion（验收标准）测试：课时子资源 CRUD + title 唯一 + 字段校验。

import (
	"encoding/json"
	"fmt"
	"net/http"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

func setupCriterionMux() (*http.ServeMux, *store.LessonStore, *store.SceneStore) {
	ls := store.NewLessonStore()
	ss := store.NewSceneStore()
	cs := store.NewCriterionStore()
	crit := NewCriterionHandler(cs, ls, ss)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /criteria", crit.ListAll)
	mux.HandleFunc("GET /criteria/{id}", crit.Get)
	mux.HandleFunc("PUT /criteria/{id}", crit.Update)
	mux.HandleFunc("DELETE /criteria/{id}", crit.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/criteria", crit.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/criteria", crit.CreateByLesson)
	mux.HandleFunc("GET /scenes/{sceneId}/criteria", crit.ListByScene)
	mux.HandleFunc("POST /scenes/{sceneId}/criteria", crit.CreateByScene)
	return mux, ls, ss
}

func TestCriterion_CRUD(t *testing.T) {
	mux, ls, _ := setupCriterionMux()
	l := ls.Create(&domain.Lesson{Title: "课时1"})

	w := request(t, mux, "POST", fmt.Sprintf("/lessons/%s/criteria", l.ID),
		`{"title":"会连接 Zed","description":"Zed 已启动且主题配置生效"}`)
	if w.Code != http.StatusCreated {
		t.Fatalf("create status = %d; body=%s", w.Code, w.Body.String())
	}
	var c map[string]any
	json.Unmarshal(w.Body.Bytes(), &c)
	criID := c["id"].(string)
	if c["lessonId"] != l.ID {
		t.Fatalf("lessonId = %v", c["lessonId"])
	}

	// 字段校验
	w = request(t, mux, "POST", fmt.Sprintf("/lessons/%s/criteria", l.ID), `{"title":"only-title"}`)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("validate status = %d", w.Code)
	}

	// 按课时列出
	w = request(t, mux, "GET", fmt.Sprintf("/lessons/%s/criteria", l.ID), "")
	if w.Code != http.StatusOK {
		t.Fatalf("list by lesson status = %d", w.Code)
	}
	var arr []map[string]any
	json.Unmarshal(w.Body.Bytes(), &arr)
	if len(arr) != 1 {
		t.Fatalf("list by lesson = %d items", len(arr))
	}

	// 全局清单
	w = request(t, mux, "GET", "/criteria", "")
	if w.Code != http.StatusOK {
		t.Fatalf("list all status = %d", w.Code)
	}

	// 更新
	w = request(t, mux, "PUT", fmt.Sprintf("/criteria/%s", criID),
		`{"title":"会连接 Zed","description":"更新后的判定规则"}`)
	if w.Code != http.StatusOK {
		t.Fatalf("update status = %d", w.Code)
	}

	// 删除
	w = request(t, mux, "DELETE", fmt.Sprintf("/criteria/%s", criID), "")
	if w.Code != http.StatusNoContent {
		t.Fatalf("delete status = %d", w.Code)
	}

	// 删除后不可见
	w = request(t, mux, "GET", fmt.Sprintf("/criteria/%s", criID), "")
	if w.Code != http.StatusNotFound {
		t.Fatalf("after delete status = %d", w.Code)
	}

	// 课时不存在
	w = request(t, mux, "POST", "/lessons/nonexistent/criteria",
		`{"title":"a/b","description":"c"}`)
	if w.Code != http.StatusNotFound {
		t.Fatalf("lesson not found status = %d", w.Code)
	}
}

func TestCriterion_SceneLevel(t *testing.T) {
	mux, ls, ss := setupCriterionMux()
	l := ls.Create(&domain.Lesson{Title: "课时1"})
	sc := ss.Create(&domain.Scene{LessonID: l.ID, Title: "开场"})

	// 场景级创建：自动回填 lessonId/sceneId
	w := request(t, mux, "POST", fmt.Sprintf("/scenes/%s/criteria", sc.ID),
		`{"title":"看完开场并完成选择","description":"进入分支前先确认终端可见"}`)
	assertStatus(t, w, 201)
	c := assertJSON(t, w)
	if c["lessonId"] != l.ID || c["sceneId"] != sc.ID {
		t.Fatalf("scene-level create = %v", c)
	}

	// 场景子路由列出
	w = request(t, mux, "GET", fmt.Sprintf("/scenes/%s/criteria", sc.ID), "")
	assertStatus(t, w, 200)
	arr := assertJSONArray(t, w)
	if len(arr) != 1 {
		t.Fatalf("ListByScene = %d, want 1", len(arr))
	}

	// 场景不存在
	w = request(t, mux, "POST", "/scenes/nonexistent/criteria",
		`{"title":"a/b","description":"c"}`)
	assertStatus(t, w, 404)
}
