package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type ProgramHandler struct {
	store *store.ProgramStore
}

func NewProgramHandler(s *store.ProgramStore) *ProgramHandler {
	return &ProgramHandler{store: s}
}

func (h *ProgramHandler) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *ProgramHandler) Create(w http.ResponseWriter, r *http.Request) {
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

func (h *ProgramHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	p, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func (h *ProgramHandler) Update(w http.ResponseWriter, r *http.Request) {
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

func (h *ProgramHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"program not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
