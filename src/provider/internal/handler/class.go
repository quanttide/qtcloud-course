package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type ClassHandler struct {
	store *store.ClassStore
}

func NewClassHandler(s *store.ClassStore) *ClassHandler {
	return &ClassHandler{store: s}
}

func (h *ClassHandler) ListClasses(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *ClassHandler) CreateClass(w http.ResponseWriter, r *http.Request) {
	var c domain.Class
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if c.Name == "" || c.RefID == "" {
		http.Error(w, `{"error":"name and refId are required"}`, http.StatusBadRequest)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&c))
}

func (h *ClassHandler) GetClass(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	c, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"class not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *ClassHandler) UpdateClass(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var c domain.Class
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	c.ID = id
	updated, ok := h.store.Update(&c)
	if !ok {
		http.Error(w, `{"error":"class not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *ClassHandler) DeleteClass(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"class not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
