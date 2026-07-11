package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// ProgramHandler 聚合 Program/Course/Lesson 的 Handler 方法。
type ProgramHandler struct {
	store *store.ProgramStore
}

func NewProgramHandler(s *store.ProgramStore) *ProgramHandler {
	return &ProgramHandler{store: s}
}

// --- Program ---

func (h *ProgramHandler) ListPrograms(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *ProgramHandler) CreateProgram(w http.ResponseWriter, r *http.Request) {
	var p domain.Program
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if p.Name == "" {
		http.Error(w, `{"error":"name is required"}`, http.StatusBadRequest)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&p))
}

func (h *ProgramHandler) GetProgram(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	p, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (h *ProgramHandler) UpdateProgram(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var p domain.Program
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	p.ID = id
	updated, ok := h.store.Update(&p)
	if !ok {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *ProgramHandler) DeleteProgram(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Course ---

func (h *ProgramHandler) ListCourses(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courses, ok := h.store.ListCourses(programID)
	if !ok {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, courses)
}

func (h *ProgramHandler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	var c domain.Course
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if c.Name == "" {
		http.Error(w, `{"error":"name is required"}`, http.StatusBadRequest)
		return
	}
	created, ok := h.store.CreateCourse(programID, &c)
	if !ok {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *ProgramHandler) GetCourse(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	c, ok := h.store.GetCourse(programID, courseID)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *ProgramHandler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	var c domain.Course
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	c.ID = courseID
	updated, ok := h.store.UpdateCourse(programID, &c)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *ProgramHandler) DeleteCourse(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	if !h.store.DeleteCourse(programID, courseID) {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Lesson ---

func (h *ProgramHandler) ListLessons(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	lessons, ok := h.store.ListLessons(programID, courseID)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, lessons)
}

func (h *ProgramHandler) CreateLesson(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if l.Title == "" {
		http.Error(w, `{"error":"title is required"}`, http.StatusBadRequest)
		return
	}
	created, ok := h.store.CreateLesson(programID, courseID, &l)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusCreated, created)
}

func (h *ProgramHandler) GetLesson(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	lessonID := r.PathValue("lessonId")
	l, ok := h.store.GetLesson(programID, courseID, lessonID)
	if !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, l)
}

func (h *ProgramHandler) UpdateLesson(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	lessonID := r.PathValue("lessonId")
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	l.ID = lessonID
	updated, ok := h.store.UpdateLesson(programID, courseID, &l)
	if !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *ProgramHandler) DeleteLesson(w http.ResponseWriter, r *http.Request) {
	programID := r.PathValue("id")
	courseID := r.PathValue("courseId")
	lessonID := r.PathValue("lessonId")
	if !h.store.DeleteLesson(programID, courseID, lessonID) {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// writeJSON 写入 JSON 响应。
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}
