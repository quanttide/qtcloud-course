package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type PhaseHandler struct {
	store       *store.PhaseStore
	courseStore *store.CourseStore
}

func NewPhaseHandler(s *store.PhaseStore, cs *store.CourseStore) *PhaseHandler {
	return &PhaseHandler{store: s, courseStore: cs}
}

func (h *PhaseHandler) List(w http.ResponseWriter, r *http.Request) {
	courseID := r.URL.Query().Get("courseId")
	if courseID != "" {
		writeJSON(w, http.StatusOK, h.store.ListByCourse(courseID))
		return
	}
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *PhaseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var p domain.Phase
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if p.Name == "" {
		http.Error(w, `{"error":"name is required"}`, http.StatusBadRequest)
		return
	}
	if p.CourseID == "" {
		http.Error(w, `{"error":"courseId is required"}`, http.StatusBadRequest)
		return
	}
	if _, ok := h.courseStore.Get(p.CourseID); !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
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
