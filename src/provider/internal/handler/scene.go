package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type SceneHandler struct {
	store       *store.SceneStore
	lessonStore *store.LessonStore
}

func NewSceneHandler(s *store.SceneStore, ls *store.LessonStore) *SceneHandler {
	return &SceneHandler{store: s, lessonStore: ls}
}

func (h *SceneHandler) List(w http.ResponseWriter, r *http.Request) {
	lessonID := r.URL.Query().Get("lessonId")
	if lessonID == "" {
		http.Error(w, `{"error":"lessonId query param is required"}`, http.StatusBadRequest)
		return
	}
	writeJSON(w, http.StatusOK, h.store.List(lessonID))
}

func (h *SceneHandler) Create(w http.ResponseWriter, r *http.Request) {
	var sc domain.Scene
	if err := json.NewDecoder(r.Body).Decode(&sc); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if sc.LessonID == "" {
		http.Error(w, `{"error":"lessonId is required"}`, http.StatusBadRequest)
		return
	}
	if _, ok := h.lessonStore.Get(sc.LessonID); !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&sc))
}

func (h *SceneHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	sc, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"scene not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, sc)
}

func (h *SceneHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var sc domain.Scene
	if err := json.NewDecoder(r.Body).Decode(&sc); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	sc.ID = id
	updated, ok := h.store.Update(&sc)
	if !ok {
		http.Error(w, `{"error":"scene not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *SceneHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"scene not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
