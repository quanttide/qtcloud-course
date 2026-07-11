package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type LessonHandler struct {
	store *store.LessonStore
}

func NewLessonHandler(s *store.LessonStore) *LessonHandler {
	return &LessonHandler{store: s}
}

func (h *LessonHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *LessonHandler) Create(w http.ResponseWriter, r *http.Request) {
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if l.Title == "" {
		http.Error(w, `{"error":"title is required"}`, http.StatusBadRequest)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&l))
}

func (h *LessonHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	l, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, l)
}

func (h *LessonHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var l domain.Lesson
	if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	l.ID = id
	updated, ok := h.store.Update(&l)
	if !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *LessonHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
