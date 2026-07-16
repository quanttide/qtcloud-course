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

// ListByLesson 列出指定课时的所有场景。
// GET /lessons/{lessonId}/scenes
func (h *SceneHandler) ListByLesson(w http.ResponseWriter, r *http.Request) {
	lessonID := r.PathValue("lessonId")
	if _, ok := h.lessonStore.Get(lessonID); !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, h.store.List(lessonID))
}

// CreateByLesson 在指定课时下创建场景。
// POST /lessons/{lessonId}/scenes
func (h *SceneHandler) CreateByLesson(w http.ResponseWriter, r *http.Request) {
	lessonID := r.PathValue("lessonId")
	if _, ok := h.lessonStore.Get(lessonID); !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	var sc domain.Scene
	if err := json.NewDecoder(r.Body).Decode(&sc); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	sc.LessonID = lessonID
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
	// 支持两种路径：/scenes/{id} 和 /lessons/{lessonId}/scenes/{id}
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"scene not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
