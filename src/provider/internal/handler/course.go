package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type CourseHandler struct {
	store *store.CourseStore
}

func NewCourseHandler(s *store.CourseStore) *CourseHandler {
	return &CourseHandler{store: s}
}

func (h *CourseHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *CourseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var c domain.Course
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if c.Name == "" {
		http.Error(w, `{"error":"name is required"}`, http.StatusBadRequest)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&c))
}

func (h *CourseHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	c, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CourseHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var c domain.Course
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	c.ID = id
	updated, ok := h.store.Update(&c)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *CourseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
