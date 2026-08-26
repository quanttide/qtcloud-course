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
	mux, err := newRouter(cfg)
	if err != nil {
		t.Fatal(err)
	}
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

// getEnv is used in main.go but tested here for coverage.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
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

// 端到端：课程 → 课时（子路由）→ 场景 → 场景级验收标准。
func TestNewRouter_CourseTree(t *testing.T) {
	cfg := config.Load()
	mux, err := newRouter(cfg)
	if err != nil {
		t.Fatal(err)
	}

	// 创建课程
	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/courses", strings.NewReader(`{"name":"生产实习","status":"published","sortOrder":1}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create course status = %d; body=%s", w.Code, w.Body.String())
	}
	var c map[string]any
	json.Unmarshal(w.Body.Bytes(), &c)
	courseID := c["id"].(string)
	if c["slug"] == "" {
		t.Fatal("course slug empty")
	}

	// 目录读入口：原始实体形态 + 排序
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/courses", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 || !strings.Contains(w.Body.String(), courseID) {
		t.Fatalf("GET /courses: status=%d body=%s", w.Code, w.Body.String())
	}
	if strings.Contains(w.Body.String(), `"icon"`) {
		t.Fatal("目录不应包含展示适配字段（icon/badge）")
	}

	// 子路由建课时
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/courses/"+courseID+"/lessons", strings.NewReader(`{"title":"创立故事","sortOrder":1,"status":"published"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create lesson status = %d", w.Code)
	}
	var l map[string]any
	json.Unmarshal(w.Body.Bytes(), &l)
	if l["courseId"] != courseID {
		t.Fatalf("lesson courseId = %v", l["courseId"])
	}
	lessonID := l["id"].(string)

	// 建场景
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/lessons/"+lessonID+"/scenes", strings.NewReader(`{"title":"开场","videoUrl":"intro.mp4","choices":[]}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create scene status = %d", w.Code)
	}
	var sc map[string]any
	json.Unmarshal(w.Body.Bytes(), &sc)
	sceneID := sc["id"].(string)

	// 场景级验收标准
	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/scenes/"+sceneID+"/criteria", strings.NewReader(`{"title":"看完开场并完成选择","description":"看完开场并完成选择"}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 201 {
		t.Fatalf("create scene criterion status = %d; body=%s", w.Code, w.Body.String())
	}
	var cri map[string]any
	json.Unmarshal(w.Body.Bytes(), &cri)
	if cri["sceneId"] != sceneID || cri["lessonId"] != lessonID {
		t.Fatalf("scene criterion = %v", cri)
	}

	// 全局清单可拉取（快照管道数据源）
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/criteria", nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 || !strings.Contains(w.Body.String(), "看完开场并完成选择") {
		t.Fatalf("GET /criteria: status=%d", w.Code)
	}
}

func TestNewRouter_404(t *testing.T) {
	cfg := config.Load()
	mux, err := newRouter(cfg)
	if err != nil {
		t.Fatal(err)
	}

	cases := []string{
		"GET /courses/nonexistent",
		"GET /lessons/nonexistent",
		"GET /scenes/nonexistent",
		"GET /criteria/nonexistent",
		"PUT /programs/nonexistent",
		"DELETE /programs/nonexistent",
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

func TestNewRouter_BadRequest(t *testing.T) {
	cfg := config.Load()
	mux, err := newRouter(cfg)
	if err != nil {
		t.Fatal(err)
	}

	w := httptest.NewRecorder()
	r := httptest.NewRequest("POST", "/courses", strings.NewReader(`{invalid`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 400 {
		t.Fatalf("bad JSON status = %d", w.Code)
	}

	w = httptest.NewRecorder()
	r = httptest.NewRequest("POST", "/courses", strings.NewReader(`{"name":""}`))
	r.Header.Set("Content-Type", "application/json")
	mux.ServeHTTP(w, r)
	if w.Code != 400 {
		t.Fatalf("empty name status = %d", w.Code)
	}
}
