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
func setupMux() (*http.ServeMux, *store.ProgramStore, *store.CourseStore, *store.LessonStore, *store.SceneStore, *store.PhaseStore, *store.ClassStore) {
	ps := store.NewProgramStore()
	cs := store.NewCourseStore()
	ls := store.NewLessonStore()
	ss := store.NewSceneStore()
	phs := store.NewPhaseStore()
	cls := store.NewClassStore()

	ph := NewProgramHandler(ps)
	ch := NewCourseHandler(cs)
	lh := NewLessonHandler(ls)
	sh := NewSceneHandler(ss, ls)
	psh := NewPhaseHandler(phs, cs)
	clh := NewClassHandler(cls)

	mux := http.NewServeMux()
	// Program
	mux.HandleFunc("GET /programs", ph.List)
	mux.HandleFunc("POST /programs", ph.Create)
	mux.HandleFunc("GET /programs/{id}", ph.Get)
	mux.HandleFunc("PUT /programs/{id}", ph.Update)
	mux.HandleFunc("DELETE /programs/{id}", ph.Delete)
	// Course
	mux.HandleFunc("GET /courses", ch.List)
	mux.HandleFunc("POST /courses", ch.Create)
	mux.HandleFunc("GET /courses/{id}", ch.Get)
	mux.HandleFunc("PUT /courses/{id}", ch.Update)
	mux.HandleFunc("DELETE /courses/{id}", ch.Delete)
	// Phase（嵌套路由 + 全局列表）
	mux.HandleFunc("GET /phases", psh.List)
	mux.HandleFunc("GET /phases/{id}", psh.Get)
	mux.HandleFunc("PUT /phases/{id}", psh.Update)
	mux.HandleFunc("DELETE /phases/{id}", psh.Delete)
	mux.HandleFunc("GET /courses/{courseId}/phases", psh.ListByCourse)
	mux.HandleFunc("POST /courses/{courseId}/phases", psh.CreateByCourse)
	// Lesson
	mux.HandleFunc("GET /lessons", lh.List)
	mux.HandleFunc("POST /lessons", lh.Create)
	mux.HandleFunc("GET /lessons/{id}", lh.Get)
	mux.HandleFunc("PUT /lessons/{id}", lh.Update)
	mux.HandleFunc("DELETE /lessons/{id}", lh.Delete)
	// Scene（嵌套路由）
	mux.HandleFunc("GET /scenes/{id}", sh.Get)
	mux.HandleFunc("PUT /scenes/{id}", sh.Update)
	mux.HandleFunc("DELETE /scenes/{id}", sh.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/scenes", sh.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/scenes", sh.CreateByLesson)
	// Class
	mux.HandleFunc("GET /classes", clh.List)
	mux.HandleFunc("POST /classes", clh.Create)
	mux.HandleFunc("GET /classes/{id}", clh.Get)
	mux.HandleFunc("PUT /classes/{id}", clh.Update)
	mux.HandleFunc("DELETE /classes/{id}", clh.Delete)
	return mux, ps, cs, ls, ss, phs, cls
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

// --- Program ---

func TestProgramHandler_CRUD(t *testing.T) {
	mux, _, _, _, _, _, _ := setupMux()

	// List empty
	w := request(t, mux, "GET", "/programs", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	// Create
	w = request(t, mux, "POST", "/programs", `{"name":"大数据微专业"}`)
	assertStatus(t, w, 201)
	p := assertJSON(t, w)
	if p["name"] != "大数据微专业" || p["id"] == "" || p["slug"] == "" {
		t.Fatalf("bad create: %v", p)
	}
	pid := p["id"].(string)

	// Create with invalid JSON
	w = request(t, mux, "POST", "/programs", `{invalid`)
	assertStatus(t, w, 400)

	// Create with empty name
	w = request(t, mux, "POST", "/programs", `{"name":""}`)
	assertStatus(t, w, 400)

	// Create duplicate name
	w = request(t, mux, "POST", "/programs", `{"name":"大数据微专业"}`)
	assertStatus(t, w, 409)

	// Get
	w = request(t, mux, "GET", fmt.Sprintf("/programs/%s", pid), "")
	assertStatus(t, w, 200)
	p = assertJSON(t, w)
	if p["name"] != "大数据微专业" {
		t.Fatalf("Get name=%q", p["name"])
	}

	// Get nonexistent
	w = request(t, mux, "GET", "/programs/nonexistent", "")
	assertStatus(t, w, 404)

	// Update
	w = request(t, mux, "PUT", fmt.Sprintf("/programs/%s", pid), `{"name":"v2","description":"desc","status":"published","courseIds":["cour-1"]}`)
	assertStatus(t, w, 200)
	p = assertJSON(t, w)
	if p["name"] != "v2" || p["status"] != "published" {
		t.Fatalf("Update = %v", p)
	}

	// Update with invalid JSON
	w = request(t, mux, "PUT", fmt.Sprintf("/programs/%s", pid), `{`)
	assertStatus(t, w, 400)

	// Update nonexistent
	w = request(t, mux, "PUT", "/programs/nonexistent", `{"name":"x"}`)
	assertStatus(t, w, 404)

	// List after creates
	w = request(t, mux, "GET", "/programs", "")
	assertStatus(t, w, 200)
	arr := assertJSONArray(t, w)
	if len(arr) != 1 {
		t.Fatalf("List = %d, want 1", len(arr))
	}

	// Delete
	w = request(t, mux, "DELETE", fmt.Sprintf("/programs/%s", pid), "")
	assertStatus(t, w, 204)

	// Delete again
	w = request(t, mux, "DELETE", fmt.Sprintf("/programs/%s", pid), "")
	assertStatus(t, w, 404)

	// Delete nonexistent
	w = request(t, mux, "DELETE", "/programs/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Course ---

func TestCourseHandler_CRUD(t *testing.T) {
	mux, _, _, _, _, _, _ := setupMux()

	w := request(t, mux, "GET", "/courses", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	w = request(t, mux, "POST", "/courses", `{"name":"数据工程"}`)
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

	// Create duplicate name
	w = request(t, mux, "POST", "/courses", `{"name":"数据工程"}`)
	assertStatus(t, w, 409)

	w = request(t, mux, "GET", fmt.Sprintf("/courses/%s", cid), "")
	assertStatus(t, w, 200)

	w = request(t, mux, "GET", "/courses/nonexistent", "")
	assertStatus(t, w, 404)

	w = request(t, mux, "PUT", fmt.Sprintf("/courses/%s", cid), `{"name":"v2","status":"published"}`)
	assertStatus(t, w, 200)
	c = assertJSON(t, w)
	if c["name"] != "v2" {
		t.Fatalf("Update name=%q", c["name"])
	}

	w = request(t, mux, "PUT", fmt.Sprintf("/courses/%s", cid), `{`)
	assertStatus(t, w, 400)

	w = request(t, mux, "PUT", "/courses/nonexistent", `{"name":"x"}`)
	assertStatus(t, w, 404)

	w = request(t, mux, "DELETE", fmt.Sprintf("/courses/%s", cid), "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", fmt.Sprintf("/courses/%s", cid), "")
	assertStatus(t, w, 404)
	w = request(t, mux, "DELETE", "/courses/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Phase ---

func TestPhaseHandler_CRUD(t *testing.T) {
	mux, _, _, _, _, _, _ := setupMux()

	// List empty
	w := request(t, mux, "GET", "/phases", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	// Create a course first
	w = request(t, mux, "POST", "/courses", `{"name":"数据工程"}`)
	assertStatus(t, w, 201)
	c := assertJSON(t, w)
	cid := c["id"].(string)

	// List phases under course (empty via nested route)
	w = request(t, mux, "GET", fmt.Sprintf("/courses/%s/phases", cid), "")
	assertStatus(t, w, 200)
	arr := assertJSONArray(t, w)
	if len(arr) != 0 {
		t.Fatalf("ListByCourse = %d, want 0", len(arr))
	}

	// Create phase via nested route
	w = request(t, mux, "POST", fmt.Sprintf("/courses/%s/phases", cid), `{"name":"数据采集阶段","sortOrder":1}`)
	assertStatus(t, w, 201)
	p := assertJSON(t, w)
	pid := p["id"].(string)
	if p["name"] != "数据采集阶段" || p["courseId"] != cid || p["sortOrder"] != float64(1) || p["slug"] == "" {
		t.Fatalf("create phase = %v", p)
	}

	// Create phase with invalid JSON
	w = request(t, mux, "POST", fmt.Sprintf("/courses/%s/phases", cid), `{invalid`)
	assertStatus(t, w, 400)

	// Create phase with empty name
	w = request(t, mux, "POST", fmt.Sprintf("/courses/%s/phases", cid), `{"name":""}`)
	assertStatus(t, w, 400)

	// Create phase under nonexistent course
	w = request(t, mux, "POST", "/courses/nonexistent/phases", `{"name":"阶段"}`)
	assertStatus(t, w, 404)

	// List phases under nonexistent course
	w = request(t, mux, "GET", "/courses/nonexistent/phases", "")
	assertStatus(t, w, 404)

	// Get
	w = request(t, mux, "GET", "/phases/"+pid, "")
	assertStatus(t, w, 200)

	w = request(t, mux, "GET", "/phases/nonexistent", "")
	assertStatus(t, w, 404)

	// List by courseId (nested)
	w = request(t, mux, "GET", fmt.Sprintf("/courses/%s/phases", cid), "")
	assertStatus(t, w, 200)
	arr = assertJSONArray(t, w)
	if len(arr) != 1 {
		t.Fatalf("ListByCourse = %d, want 1", len(arr))
	}

	w = request(t, mux, "PUT", "/phases/"+pid, `{"name":"v2","sortOrder":2,"lessonIds":["less-1"]}`)
	assertStatus(t, w, 200)
	p = assertJSON(t, w)
	if p["name"] != "v2" || p["sortOrder"] != float64(2) {
		t.Fatalf("update phase = %v", p)
	}

	w = request(t, mux, "PUT", "/phases/"+pid, `{`)
	assertStatus(t, w, 400)

	w = request(t, mux, "PUT", "/phases/nonexistent", `{"name":"x"}`)
	assertStatus(t, w, 404)

	w = request(t, mux, "DELETE", "/phases/"+pid, "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", "/phases/"+pid, "")
	assertStatus(t, w, 404)
	w = request(t, mux, "DELETE", "/phases/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Lesson ---

func TestLessonHandler_CRUD(t *testing.T) {
	mux, _, _, _, _, _, _ := setupMux()

	w := request(t, mux, "GET", "/lessons", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	w = request(t, mux, "POST", "/lessons", `{"title":"课时1","duration":45}`)
	assertStatus(t, w, 201)
	l := assertJSON(t, w)
	lid := l["id"].(string)
	if l["slug"] == "" {
		t.Fatal("slug is empty")
	}

	w = request(t, mux, "POST", "/lessons", `{invalid`)
	assertStatus(t, w, 400)

	w = request(t, mux, "POST", "/lessons", `{"title":""}`)
	assertStatus(t, w, 400)

	// Create duplicate title
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
	mux, _, _, _, _, _, _ := setupMux()

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

	// List for nonexistent lesson
	w = request(t, mux, "GET", "/lessons/nonexistent/scenes", "")
	assertStatus(t, w, 404)

	// Get
	w = request(t, mux, "GET", fmt.Sprintf("/scenes/%s", scid), "")
	assertStatus(t, w, 200)

	// Get nonexistent
	w = request(t, mux, "GET", "/scenes/nonexistent", "")
	assertStatus(t, w, 404)

	// Update
	w = request(t, mux, "PUT", fmt.Sprintf("/scenes/%s", scid), `{"videoUrl":"v2.mp4","choices":[{"label":"跳过","targetSceneId":"scene-3"}]}`)
	assertStatus(t, w, 200)
	sc = assertJSON(t, w)
	if sc["videoUrl"] != "v2.mp4" {
		t.Fatalf("Update videoUrl=%q", sc["videoUrl"])
	}

	// Update with invalid JSON
	w = request(t, mux, "PUT", fmt.Sprintf("/scenes/%s", scid), `{`)
	assertStatus(t, w, 400)

	// Update nonexistent
	w = request(t, mux, "PUT", "/scenes/nonexistent", `{"videoUrl":"x.mp4"}`)
	assertStatus(t, w, 404)

	// Delete
	w = request(t, mux, "DELETE", fmt.Sprintf("/scenes/%s", scid), "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", fmt.Sprintf("/scenes/%s", scid), "")
	assertStatus(t, w, 404)
	w = request(t, mux, "DELETE", "/scenes/nonexistent", "")
	assertStatus(t, w, 404)
}

// --- Class ---

func TestClassHandler_CRUD(t *testing.T) {
	mux, _, _, _, _, _, _ := setupMux()

	w := request(t, mux, "GET", "/classes", "")
	assertStatus(t, w, 200)
	assertJSONArray(t, w)

	w = request(t, mux, "POST", "/classes", `{"name":"浙理班级","refName":"大数据微专业","refType":"program","refId":"prog-1","startDate":"2026-09-01","endDate":"2027-01-15","studentCount":30}`)
	assertStatus(t, w, 201)
	c := assertJSON(t, w)
	cid := c["id"].(string)
	if c["slug"] == "" {
		t.Fatal("slug is empty")
	}

	w = request(t, mux, "POST", "/classes", `{invalid`)
	assertStatus(t, w, 400)

	w = request(t, mux, "POST", "/classes", `{"name":"x"}`)
	assertStatus(t, w, 400)

	w = request(t, mux, "POST", "/classes", `{"refId":"prog-1"}`)
	assertStatus(t, w, 400)

	// Create duplicate name
	w = request(t, mux, "POST", "/classes", `{"name":"浙理班级","refId":"prog-2"}`)
	assertStatus(t, w, 409)

	w = request(t, mux, "GET", fmt.Sprintf("/classes/%s", cid), "")
	assertStatus(t, w, 200)

	w = request(t, mux, "GET", "/classes/nonexistent", "")
	assertStatus(t, w, 404)

	w = request(t, mux, "PUT", fmt.Sprintf("/classes/%s", cid), `{"name":"v2","refName":"v2","refType":"course","refId":"cour-1","status":"active","startDate":"2026-09-15","endDate":"2027-02-01","studentCount":35,"progress":0.5}`)
	assertStatus(t, w, 200)
	c = assertJSON(t, w)
	if c["name"] != "v2" || c["studentCount"] != float64(35) || c["progress"] != 0.5 {
		t.Fatalf("Update = %v", c)
	}

	w = request(t, mux, "PUT", fmt.Sprintf("/classes/%s", cid), `{`)
	assertStatus(t, w, 400)

	w = request(t, mux, "PUT", "/classes/nonexistent", `{"name":"x","refId":"prog-1"}`)
	assertStatus(t, w, 404)

	w = request(t, mux, "DELETE", fmt.Sprintf("/classes/%s", cid), "")
	assertStatus(t, w, 204)
	w = request(t, mux, "DELETE", fmt.Sprintf("/classes/%s", cid), "")
	assertStatus(t, w, 404)
	w = request(t, mux, "DELETE", "/classes/nonexistent", "")
	assertStatus(t, w, 404)
}
