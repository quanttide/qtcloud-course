package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/quanttide/qtcloud-course-provider-example/internal/store"
)

func testSetup(t *testing.T) (store.Store, func()) {
	t.Helper()
	dir, err := os.MkdirTemp("", "api-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	s, err := store.New(store.Config{Driver: "file", Path: dir})
	if err != nil {
		os.RemoveAll(dir)
		t.Fatalf("failed to create store: %v", err)
	}
	return s, func() {
		s.Close()
		os.RemoveAll(dir)
	}
}

func registerCourseRoutes(h *CourseHandler) *http.ServeMux {
	mux := http.NewServeMux()
	// qtclass
	mux.HandleFunc("GET /api/v1/qtclass/courses", h.ListCourses)
	mux.HandleFunc("POST /api/v1/qtclass/courses", h.CreateCourse)
	mux.HandleFunc("GET /api/v1/qtclass/courses/{id}", h.GetCourse)
	mux.HandleFunc("PUT /api/v1/qtclass/courses/{id}", h.UpdateCourse)
	mux.HandleFunc("DELETE /api/v1/qtclass/courses/{id}", h.DeleteCourse)
	mux.HandleFunc("GET /api/v1/qtclass/schedules", h.ListSchedules)
	mux.HandleFunc("POST /api/v1/qtclass/enrollments", h.CreateEnrollment)
	return mux
}

func TestCourseCRUD(t *testing.T) {
	s, cleanup := testSetup(t)
	defer cleanup()

	h := NewCourseHandler(s)
	mux := registerCourseRoutes(h)
	base := "/api/v1/qtclass/courses"

	t.Run("Create and Get", func(t *testing.T) {
		body := `{"name":"Go 101","teacher":"Alice","max_students":30,"status":"active"}`
		req := httptest.NewRequest("POST", base, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201, got %d", rec.Code)
		}

		var item map[string]any
		json.Unmarshal(rec.Body.Bytes(), &item)
		id := item["id"].(string)

		req = httptest.NewRequest("GET", base+"/"+id, nil)
		rec = httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", rec.Code)
		}
	})

	t.Run("Schedules", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/qtclass/schedules", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Errorf("expected 200, got %d", rec.Code)
		}
	})

	t.Run("Enrollment", func(t *testing.T) {
		body := `{"course_id":"c1","student":"Bob"}`
		req := httptest.NewRequest("POST", "/api/v1/qtclass/enrollments", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusCreated {
			t.Errorf("expected 201, got %d", rec.Code)
		}
	})
}

func TestCourseUpdateDelete(t *testing.T) {
	s, cleanup := testSetup(t)
	defer cleanup()

	h := NewCourseHandler(s)
	mux := registerCourseRoutes(h)
	base := "/api/v1/qtclass/courses"

	t.Run("List empty", func(t *testing.T) {
		req := httptest.NewRequest("GET", base, nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", rec.Code)
		}
	})

	t.Run("Update", func(t *testing.T) {
		body := `{"name":"Go 101","teacher":"Alice","max_students":30,"status":"active"}`
		req := httptest.NewRequest("POST", base, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		var item map[string]any
		json.Unmarshal(rec.Body.Bytes(), &item)
		id := item["id"].(string)

		updateBody := `{"name":"Go 102","teacher":"Bob","max_students":25,"status":"inactive"}`
		req = httptest.NewRequest("PUT", base+"/"+id, strings.NewReader(updateBody))
		req.Header.Set("Content-Type", "application/json")
		rec = httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
		}
		var updated map[string]any
		json.Unmarshal(rec.Body.Bytes(), &updated)
		if updated["name"] != "Go 102" {
			t.Errorf("expected name=Go 102, got %v", updated["name"])
		}
	})

	t.Run("List after create", func(t *testing.T) {
		req := httptest.NewRequest("GET", base, nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", rec.Code)
		}
	})

	t.Run("Delete", func(t *testing.T) {
		body := `{"name":"Temp Course"}`
		req := httptest.NewRequest("POST", base, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		var item map[string]any
		json.Unmarshal(rec.Body.Bytes(), &item)
		id := item["id"].(string)

		req = httptest.NewRequest("DELETE", base+"/"+id, nil)
		rec = httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusNoContent {
			t.Errorf("expected 204, got %d", rec.Code)
		}
	})

	t.Run("Delete not found", func(t *testing.T) {
		req := httptest.NewRequest("DELETE", base+"/nonexistent", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusNotFound {
			t.Errorf("expected 404, got %d", rec.Code)
		}
	})
}
