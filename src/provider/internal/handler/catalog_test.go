package handler

// 课程读入口测试：/courses 列表（SortOrder 排序）/ 详情。

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// setupReadMux 内存 store + 路由（与 buildMux 对齐）。
func setupReadMux() (*http.ServeMux, *store.CourseStore, *store.LessonStore) {
	cs := store.NewCourseStore()
	ls := store.NewLessonStore()

	cr := NewCourseReadHandler(cs)
	lh := NewLessonHandler(ls, cs)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /courses", cr.List)
	mux.HandleFunc("GET /courses/{id}", cr.Get)
	mux.HandleFunc("POST /courses", func(w http.ResponseWriter, r *http.Request) {})
	mux.HandleFunc("GET /courses/{courseId}/lessons", lh.ListByCourse)
	return mux, cs, ls
}

func TestCourseList_SortOrder(t *testing.T) {
	mux, cs, _ := setupReadMux()

	// 乱序创建：SortOrder 决定列表顺序
	c1 := cs.Create(&domain.Course{Name: "知识工作", Status: "published", SortOrder: 1})
	cs.SetID(c1, "knowledge-work")
	c2 := cs.Create(&domain.Course{Name: "数据工程", Status: "published", SortOrder: 2})
	cs.SetID(c2, "data-engineering")

	req := httptest.NewRequest("GET", "/courses", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d", w.Code)
	}
	var courses []map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &courses); err != nil {
		t.Fatalf("decode: %v (body=%s)", err, w.Body.String())
	}
	if len(courses) != 2 {
		t.Fatalf("courses = %d, want 2", len(courses))
	}
	if courses[0]["id"] != "knowledge-work" || courses[1]["id"] != "data-engineering" {
		t.Fatalf("order = %v", courses)
	}

	// 详情
	req = httptest.NewRequest("GET", "/courses/prod", nil)
	w = httptest.NewRecorder()
	mux.ServeHTTP(w, req)
	if w.Code != http.StatusNotFound {
		t.Fatalf("detail nonexistent status = %d", w.Code)
	}
}
