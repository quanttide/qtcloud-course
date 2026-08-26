package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// setupMux creates a fresh mux with all routes for testing.
func setupMux() (*http.ServeMux, *store.CourseStore, *store.LessonStore, *store.SceneStore) {
	cs := store.NewCourseStore()
	ls := store.NewLessonStore()
	ss := store.NewSceneStore()

	ch := NewCourseHandler(cs)
	crh := NewCourseReadHandler(cs)
	lh := NewLessonHandler(ls, cs)
	sh := NewSceneHandler(ss, ls)

	mux := http.NewServeMux()
	// Course
	mux.HandleFunc("GET /courses", crh.List)
	mux.HandleFunc("GET /courses/{id}", crh.Get)
	mux.HandleFunc("POST /courses", ch.Create)
	mux.HandleFunc("PUT /courses/{id}", ch.Update)
	mux.HandleFunc("DELETE /courses/{id}", ch.Delete)
	// Lesson
	mux.HandleFunc("GET /lessons", lh.List)
	mux.HandleFunc("POST /lessons", lh.Create)
	mux.HandleFunc("GET /lessons/{id}", lh.Get)
	mux.HandleFunc("PUT /lessons/{id}", lh.Update)
	mux.HandleFunc("DELETE /lessons/{id}", lh.Delete)
	mux.HandleFunc("GET /courses/{courseId}/lessons", lh.ListByCourse)
	mux.HandleFunc("POST /courses/{courseId}/lessons", lh.CreateByCourse)
	// Scene
	mux.HandleFunc("GET /scenes/{id}", sh.Get)
	mux.HandleFunc("PUT /scenes/{id}", sh.Update)
	mux.HandleFunc("DELETE /scenes/{id}", sh.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/scenes", sh.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/scenes", sh.CreateByLesson)
	return mux, cs, ls, ss
}

func request(t *testing.T, mux *http.ServeMux, method, path, body string) *httptest.ResponseRecorder {
	t.Helper()
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	if body != "" {
		r.Header.Set("Content-Type", "application/json")
	}
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, r)
	return w
}

func assertStatus(t *testing.T, w *httptest.ResponseRecorder, want int) {
	t.Helper()
	if w.Code != want {
		t.Errorf("status = %d, want %d; body = %s", w.Code, want, w.Body.String())
	}
}

func assertJSON(t *testing.T, w *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var data map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &data); err != nil {
		t.Fatalf("invalid JSON: %v; body=%s", err, w.Body.String())
	}
	return data
}

func assertJSONArray(t *testing.T, w *httptest.ResponseRecorder) []any {
	t.Helper()
	var data []any
	if err := json.Unmarshal(w.Body.Bytes(), &data); err != nil {
		t.Fatalf("invalid JSON array: %v; body=%s", err, w.Body.String())
	}
	return data
}

// --- Course ---

func TestCourseHandler_WriteOps(t *testing.T) {
	mux, _, _, _ := setupMux()

	w := request(t, mux, "GET", "/courses", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	w = request(t, mux, "POST", "/courses", `{"name":"数据工程","status":"published","sortOrder":1}`)
	assertStatus(t, w, 201)
	c := assertJSON(t, w)
	cid := c["id"].(string)
	if c["slug"] == "" {
		t.Fatal("slug is empty")
	}

	w = request(t, mux, "POST", "/courses", `{invalid`)
	assertStatus(t, w, 400)

	w = request(t, mux, "POST", "/courses", `{"name":""}`)
	assertStatus(t, w, 400)

	// 名称唯一
	w = request(t, mux, "POST", "/courses", `{"name":"数据工程"}`)
	assertStatus(t, w, 409)

	w = request(t, mux, "PUT", fmt.Sprintf("/courses/%s", cid), `{"name":"数据工程v2","description":"desc","status":"published"}`)
	assertStatus(t, w, 200)
	c = assertJSON(t, w)
	if c["name"] != "数据工程v2" || c["status"] != "published" {
		t.Fatalf("Update = %v", c)
	}

	w = request(t, mux, "PUT", fmt.Sprintf("/courses/%s", cid), `{`)
	assertStatus(t, w, 400)

	w = request(t, mux, "PUT", "/courses/nonexistent", `{"name":"x"}`)
	assertStatus(t, w, 404)

	w = request(t, mux, "DELETE", fmt.Sprintf("/courses/%s", cid), "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", "/courses/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Lesson ---

func TestLessonHandler_CRUD(t *testing.T) {
	mux, _, _, _ := setupMux()

	w := request(t, mux, "GET", "/lessons", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	// 建课程后经子路由创建课时
	w = request(t, mux, "POST", "/courses", `{"name":"生产实习"}`)
	assertStatus(t, w, 201)
	courseID := assertJSON(t, w)["id"].(string)

	w = request(t, mux, "POST", fmt.Sprintf("/courses/%s/lessons", courseID), `{"title":"课时1","duration":45,"sortOrder":1}`)
	assertStatus(t, w, 201)
	l := assertJSON(t, w)
	lid := l["id"].(string)
	if l["courseId"] != courseID || l["slug"] == "" {
		t.Fatalf("Create by course = %v", l)
	}

	// 课程不存在
	w = request(t, mux, "POST", "/courses/nonexistent/lessons", `{"title":"x"}`)
	assertStatus(t, w, 404)

	// 子路由列出课时
	w = request(t, mux, "GET", fmt.Sprintf("/courses/%s/lessons", courseID), "")
	assertStatus(t, w, 200)
	arr := assertJSONArray(t, w)
	if len(arr) != 1 {
		t.Fatalf("ListByCourse = %d, want 1", len(arr))
	}

	w = request(t, mux, "POST", "/lessons", `{invalid`)
	assertStatus(t, w, 400)

	w = request(t, mux, "POST", "/lessons", `{"title":""}`)
	assertStatus(t, w, 400)

	// title 全局唯一（跨课程也不允许重复）
	w = request(t, mux, "POST", "/lessons", `{"title":"课时1"}`)
	assertStatus(t, w, 409)

	w = request(t, mux, "GET", fmt.Sprintf("/lessons/%s", lid), "")
	assertStatus(t, w, 200)

	w = request(t, mux, "GET", "/lessons/nonexistent", "")
	assertStatus(t, w, 404)

	w = request(t, mux, "PUT", fmt.Sprintf("/lessons/%s", lid), `{"title":"v2","duration":50,"startSceneId":"scene-1"}`)
	assertStatus(t, w, 200)
	l = assertJSON(t, w)
	if l["title"] != "v2" || l["duration"] != float64(50) || l["startSceneId"] != "scene-1" {
		t.Fatalf("Update = %v", l)
	}

	w = request(t, mux, "PUT", fmt.Sprintf("/lessons/%s", lid), `{`)
	assertStatus(t, w, 400)

	w = request(t, mux, "PUT", "/lessons/nonexistent", `{"title":"x"}`)
	assertStatus(t, w, 404)

	w = request(t, mux, "DELETE", fmt.Sprintf("/lessons/%s", lid), "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", fmt.Sprintf("/lessons/%s", lid), "")
	assertStatus(t, w, 404)
	w = request(t, mux, "DELETE", "/lessons/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Scene ---

func TestSceneHandler_CRUD(t *testing.T) {
	mux, _, _, _ := setupMux()

	// List scenes under nonexistent lesson
	w := request(t, mux, "GET", "/lessons/nonexistent/scenes", "")
	assertStatus(t, w, 404)

	// Create scene under nonexistent lesson
	w = request(t, mux, "POST", "/lessons/nonexistent/scenes", `{"videoUrl":"intro.mp4"}`)
	assertStatus(t, w, 404)

	// Create a lesson first
	w = request(t, mux, "POST", "/lessons", `{"title":"Git 入门"}`)
	assertStatus(t, w, 201)
	l := assertJSON(t, w)
	lid := l["id"].(string)

	// List scenes (empty via nested)
	w = request(t, mux, "GET", fmt.Sprintf("/lessons/%s/scenes", lid), "")
	assertStatus(t, w, 200)
	arr := assertJSONArray(t, w)
	if len(arr) != 0 {
		t.Fatalf("ListByLesson = %d, want 0", len(arr))
	}

	// Create scene via nested route
	w = request(t, mux, "POST", fmt.Sprintf("/lessons/%s/scenes", lid), `{"title":"开场","videoUrl":"intro.mp4","choices":[{"label":"继续","targetSceneId":"scene-99"}]}`)
	assertStatus(t, w, 201)
	sc := assertJSON(t, w)
	scid := sc["id"].(string)
	if sc["videoUrl"] != "intro.mp4" || sc["lessonId"] != lid || sc["slug"] == "" {
		t.Fatalf("Create scene = %v", sc)
	}

	// Create scene with no choices
	w = request(t, mux, "POST", fmt.Sprintf("/lessons/%s/scenes", lid), `{"title":"结尾","videoUrl":"outro.mp4"}`)
	assertStatus(t, w, 201)
	sc2 := assertJSON(t, w)
	if choices, ok := sc2["choices"].([]any); !ok || len(choices) != 0 {
		t.Fatalf("outro scene choices = %v, want empty array", sc2["choices"])
	}

	// Create with invalid JSON
	w = request(t, mux, "POST", fmt.Sprintf("/lessons/%s/scenes", lid), `{`)
	assertStatus(t, w, 400)

	// List by lesson
	w = request(t, mux, "GET", fmt.Sprintf("/lessons/%s/scenes", lid), "")
	assertStatus(t, w, 200)
	arr = assertJSONArray(t, w)
	if len(arr) != 2 {
		t.Fatalf("List scenes = %d, want 2", len(arr))
	}

	// Get
	w = request(t, mux, "GET", fmt.Sprintf("/scenes/%s", scid), "")
	assertStatus(t, w, 200)

	// Update
	w = request(t, mux, "PUT", fmt.Sprintf("/scenes/%s", scid), `{"videoUrl":"v2.mp4","choices":[{"label":"跳过","targetSceneId":"scene-3"}]}`)
	assertStatus(t, w, 200)
	sc = assertJSON(t, w)
	if sc["videoUrl"] != "v2.mp4" {
		t.Fatalf("Update videoUrl=%q", sc["videoUrl"])
	}

	// Delete
	w = request(t, mux, "DELETE", fmt.Sprintf("/scenes/%s", scid), "")
	assertStatus(t, w, 204)
}
