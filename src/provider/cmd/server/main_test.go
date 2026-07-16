package main

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/config"
)

func TestNewRouter_Healthz(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)
	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/healthz", nil)
	mux.ServeHTTP(w, r)

	if w.Code != 200 {
		t.Fatalf("status = %d", w.Code)
	}
	if w.Body.String() != `{"status":"ok"}` {
		t.Fatalf("body = %s", w.Body.String())
	}
}

func TestNewRouter_ProgramCRUD(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)

	// Create
	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/programs", strings.NewReader(`{"name":"大数据微专业"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create status = %d; body=%s", w.Code, w.Body.String())
	}
	var p map[string]any
	json.Unmarshal(w.Body.Bytes(), &p)
	pid := p["id"].(string)
	if p["slug"] == "" {
		t.Fatalf("create: slug is empty")
	}

	// Get
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/programs/"+pid, nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("get status = %d", w.Code)
	}
}

func TestNewRouter_404(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)

	cases := []string{
		"GET /programs/nonexistent",
		"PUT /programs/nonexistent",
		"DELETE /programs/nonexistent",
		"GET /courses/nonexistent",
		"GET /lessons/nonexistent",
		"GET /scenes/nonexistent",
		"GET /classes/nonexistent",
	}
	for _, tc := range cases {
		parts := strings.SplitN(tc, " ", 2)
		w := httptest.NewRecorder()
		var rdr io.Reader
		if parts[0] == "PUT" {
			rdr = strings.NewReader(`{"name":"x"}`)
		}
		r := httptest.NewRequest(parts[0], parts[1], rdr)
		if rdr != nil {
			r.Header.Set("Content-Type", "application/json")
		}
		mux.ServeHTTP(w, r)
		if w.Code != 404 {
			t.Errorf("%s: status = %d, want 404; body=%s", tc, w.Code, w.Body.String())
		}
	}
}

func TestGetEnv(t *testing.T) {
	if got := getEnv("NONEXISTENT_KEY_XYZ", "default"); got != "default" {
		t.Fatalf("getEnv() = %q, want %q", got, "default")
	}
	os.Setenv("TEST_GETENV_KEY", "custom")
	defer os.Unsetenv("TEST_GETENV_KEY")
	if got := getEnv("TEST_GETENV_KEY", "default"); got != "custom" {
		t.Fatalf("getEnv() = %q, want %q", got, "custom")
	}
}

func TestNewRouter_BadRequest(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)

	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/programs", strings.NewReader(`{invalid`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 400 {
		t.Fatalf("bad JSON status = %d", w.Code)
	}

	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/programs", strings.NewReader(`{"name":""}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 400 {
		t.Fatalf("empty name status = %d", w.Code)
	}
}

// getEnv is used in main.go but tested here for coverage.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func TestNewRouter_SceneNestedRoutes(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)

	// Create a lesson first
	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/lessons", strings.NewReader(`{"title":"Git 入门"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create lesson status = %d", w.Code)
	}
	var lesson map[string]any
	json.Unmarshal(w.Body.Bytes(), &lesson)
	lid := lesson["id"].(string)

	// List scenes under lesson (empty)
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/lessons/"+lid+"/scenes", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("list scenes status = %d", w.Code)
	}

	// Create scene under lesson (nested route)
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/lessons/"+lid+"/scenes", strings.NewReader(`{"title":"开场","videoUrl":"intro.mp4"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create scene nested status = %d; body=%s", w.Code, w.Body.String())
	}
	var scene map[string]any
	json.Unmarshal(w.Body.Bytes(), &scene)
	scid := scene["id"].(string)
	if scene["lessonId"] != lid {
		t.Fatalf("scene lessonId = %v, want %s", scene["lessonId"], lid)
	}
	if scene["slug"] == "" {
		t.Fatal("scene slug is empty")
	}

	// Get scene by flat route
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/scenes/"+scid, nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("get scene status = %d", w.Code)
	}

	// Create scene under nonexistent lesson
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/lessons/nonexistent/scenes", strings.NewReader(`{"title":"x","videoUrl":"x.mp4"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 404 {
		t.Fatalf("create scene under nonexistent lesson status = %d, want 404", w.Code)
	}

	// List scenes under nonexistent lesson
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/lessons/nonexistent/scenes", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 404 {
		t.Fatalf("list scenes under nonexistent lesson status = %d, want 404", w.Code)
	}
}

func TestNewRouter_PhaseNestedRoutes(t *testing.T) {
	cfg := config.Load()
	mux := newRouter(cfg)

	// Create a course first
	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/courses", strings.NewReader(`{"name":"数据工程"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create course status = %d", w.Code)
	}
	var course map[string]any
	json.Unmarshal(w.Body.Bytes(), &course)
	cid := course["id"].(string)

	// List phases under course (empty)
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/courses/"+cid+"/phases", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("list phases status = %d", w.Code)
	}

	// Create phase under course (nested route)
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/courses/"+cid+"/phases", strings.NewReader(`{"name":"数据采集阶段","sortOrder":1}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create phase nested status = %d; body=%s", w.Code, w.Body.String())
	}
	var phase map[string]any
	json.Unmarshal(w.Body.Bytes(), &phase)
	pid := phase["id"].(string)
	if phase["courseId"] != cid {
		t.Fatalf("phase courseId = %v, want %s", phase["courseId"], cid)
	}
	if phase["slug"] == "" {
		t.Fatal("phase slug is empty")
	}

	// Create phase with empty name
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/courses/"+cid+"/phases", strings.NewReader(`{"name":""}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 400 {
		t.Fatalf("create phase empty name status = %d, want 400", w.Code)
	}

	// Create phase under nonexistent course
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/courses/nonexistent/phases", strings.NewReader(`{"name":"阶段"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 404 {
		t.Fatalf("create phase under nonexistent course status = %d, want 404", w.Code)
	}

	// List phases under nonexistent course
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/courses/nonexistent/phases", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 404 {
		t.Fatalf("list phases under nonexistent course status = %d, want 404", w.Code)
	}

	// Get phase by flat route
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/phases/"+pid, nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("get phase status = %d", w.Code)
	}

	// List all phases
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/phases", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("list all phases status = %d", w.Code)
	}
}
