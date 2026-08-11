package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	)

type PhaseHandler struct {
	store       PhaseStorer
	courseStore CourseStorer
}

func NewPhaseHandler(s PhaseStorer, cs CourseStorer) *PhaseHandler {
	return &PhaseHandler{store: s, courseStore: cs}
}

// List 返回所有阶段（全局列表）。
func (h *PhaseHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

// ListByCourse 返回指定课程下的所有阶段。
// GET /courses/{courseId}/phases
func (h *PhaseHandler) ListByCourse(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	if _, ok := h.courseStore.Get(courseID); !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, h.store.ListWhere("courseId", courseID))
}

// CreateByCourse 在指定课程下创建阶段。
// POST /courses/{courseId}/phases
func (h *PhaseHandler) CreateByCourse(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	if _, ok := h.courseStore.Get(courseID); !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	var p domain.Phase
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if p.Name == "" {
		http.Error(w, `{"error":"name is required"}`, http.StatusBadRequest)
		return
	}
	p.CourseID = courseID
	writeJSON(w, http.StatusCreated, h.store.Create(&p))
}

func (h *PhaseHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	p, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"phase not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (h *PhaseHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var p domain.Phase
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	p.ID = id
	updated, ok := h.store.Update(&p)
	if !ok {
		http.Error(w, `{"error":"phase not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *PhaseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"phase not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
