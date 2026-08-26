package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// LessonHandler 提供 Lesson 的 CRUD：全局接口 + 课程子资源接口。
type LessonHandler struct {
	store       LessonStorer
	courseStore CourseStorer
}

func NewLessonHandler(s LessonStorer, cs CourseStorer) *LessonHandler {
	return &LessonHandler{store: s, courseStore: cs}
}

// List GET /lessons：全部课时。
func (h *LessonHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

// Get GET /lessons/{id}
func (h *LessonHandler) Get(w http.ResponseWriter, r *http.Request) {
	l, ok := h.store.Get(r.PathValue("id"))
	if !ok {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, l)
}

// Update PUT /lessons/{id}
func (h *LessonHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := validateLesson(&l); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	if h.store.NameExists(l.Title, func(x *domain.Lesson) string { return x.Title }) {
		http.Error(w, `{"error":"name already exists"}`, http.StatusConflict)
		return
	}
	l.ID = id
	updated, ok := h.store.Update(&l)
	if !ok {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

// Delete DELETE /lessons/{id}
func (h *LessonHandler) Delete(w http.ResponseWriter, r *http.Request) {
	if !h.store.Delete(r.PathValue("id")) {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListByCourse GET /courses/{courseId}/lessons：列出指定课程的课时。
func (h *LessonHandler) ListByCourse(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	writeJSON(w, http.StatusOK, h.store.ListWhere("courseId", courseID))
}

// CreateByCourse POST /courses/{courseId}/lessons：在指定课程下创建课时。
func (h *LessonHandler) CreateByCourse(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	if _, ok := h.courseStore.Get(courseID); !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := validateLesson(&l); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	if h.store.NameExists(l.Title, func(x *domain.Lesson) string { return x.Title }) {
		http.Error(w, `{"error":"name already exists"}`, http.StatusConflict)
		return
	}
	l.CourseID = courseID
	writeJSON(w, http.StatusCreated, h.store.Create(&l))
}

// Create POST /lessons：创建课时（courseId 可由请求体指定）。
func (h *LessonHandler) Create(w http.ResponseWriter, r *http.Request) {
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := validateLesson(&l); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	if h.store.NameExists(l.Title, func(x *domain.Lesson) string { return x.Title }) {
		http.Error(w, `{"error":"name already exists"}`, http.StatusConflict)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&l))
}

func validateLesson(l *domain.Lesson) string {
	if l.Title == "" {
		return "title is required"
	}
	return ""
}
