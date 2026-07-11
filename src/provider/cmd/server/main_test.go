package main

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

func TestNewRouter_Healthz(t *testing.T) {
	mux := newRouter()
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
	mux := newRouter()

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

	// Get
	w = httptest.NewRecorder()
	r = httptest.NewRequest("GET", "/programs/"+pid, nil)
	mux.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("get status = %d", w.Code)
	}
}

func TestNewRouter_404(t *testing.T) {
	mux := newRouter()

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
	mux := newRouter()

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
