package api

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider-example/internal/model"
	"github.com/quanttide/qtcloud-course-provider-example/internal/store"
)

type CourseHandler struct {
	store store.Store
}

func NewCourseHandler(st store.Store) *CourseHandler {
	return &CourseHandler{store: st}
}

// --- QtClass Courses ---

func (h *CourseHandler) ListCourses(w http.ResponseWriter, r *http.Request) {
	data, err := h.store.List("qtclass/courses")
	if err != nil {
		slog.Error("list courses", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to list courses", http.StatusInternalServerError)
		return
	}
	var items []model.QtClassCourse
	if err := json.Unmarshal(data, &items); err != nil {
		slog.Error("parse courses", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to parse courses", http.StatusInternalServerError)
		return
	}
	WriteJSON(w, items, http.StatusOK)
}

func (h *CourseHandler) CreateCourse(w http.ResponseWriter, r *http.Request) {
	var item model.QtClassCourse
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		WriteError(w, "INVALID_INPUT", "invalid request body", http.StatusBadRequest)
		return
	}
	if item.Name == "" {
		WriteError(w, "VALIDATION_ERROR", "name is required", http.StatusBadRequest)
		return
	}

	data, err := json.Marshal(item)
	if err != nil {
		slog.Error("encode course", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to encode data", http.StatusInternalServerError)
		return
	}

	id, err := h.store.Create("qtclass/courses", data)
	if err != nil {
		slog.Error("create course", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to create course", http.StatusInternalServerError)
		return
	}

	item.ID = id
	data, err = json.Marshal(item)
	if err != nil {
		slog.Error("encode course with id", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to encode data", http.StatusInternalServerError)
		return
	}
	if err := h.store.Update("qtclass/courses", id, data); err != nil {
		slog.Error("persist course id", "error", err)
	}

	WriteJSON(w, item, http.StatusCreated)
}

func (h *CourseHandler) GetCourse(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	data, err := h.store.Get("qtclass/courses", id)
	if err != nil {
		WriteError(w, "NOT_FOUND", "course not found", http.StatusNotFound)
		return
	}
	var item model.QtClassCourse
	if err := json.Unmarshal(data, &item); err != nil {
		slog.Error("parse course", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to parse course", http.StatusInternalServerError)
		return
	}
	WriteJSON(w, item, http.StatusOK)
}

func (h *CourseHandler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var item model.QtClassCourse
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		WriteError(w, "INVALID_INPUT", "invalid request body", http.StatusBadRequest)
		return
	}
	item.ID = id

	data, err := json.Marshal(item)
	if err != nil {
		slog.Error("encode course", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to encode data", http.StatusInternalServerError)
		return
	}
	if err := h.store.Update("qtclass/courses", id, data); err != nil {
		WriteError(w, "NOT_FOUND", "course not found", http.StatusNotFound)
		return
	}
	WriteJSON(w, item, http.StatusOK)
}

func (h *CourseHandler) DeleteCourse(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := h.store.Delete("qtclass/courses", id); err != nil {
		WriteError(w, "NOT_FOUND", "course not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- QtClass Schedules ---

func (h *CourseHandler) ListSchedules(w http.ResponseWriter, r *http.Request) {
	data, err := h.store.List("qtclass/courses")
	if err != nil {
		slog.Error("list schedules", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to list schedules", http.StatusInternalServerError)
		return
	}
	var items []model.QtClassCourse
	if err := json.Unmarshal(data, &items); err != nil {
		slog.Error("parse schedules", "error", err)
		WriteError(w, "INTERNAL_ERROR", "failed to parse schedules", http.StatusInternalServerError)
		return
	}
	WriteJSON(w, items, http.StatusOK)
}

func (h *CourseHandler) CreateEnrollment(w http.ResponseWriter, r *http.Request) {
	var body struct {
		CourseID string `json:"course_id"`
		Student  string `json:"student"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		WriteError(w, "INVALID_INPUT", "invalid request body", http.StatusBadRequest)
		return
	}
	if body.CourseID == "" || body.Student == "" {
		WriteError(w, "VALIDATION_ERROR", "course_id and student are required", http.StatusBadRequest)
		return
	}
	WriteJSON(w, body, http.StatusCreated)
}
