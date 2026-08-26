// CriterionHandler 提供 Criterion（验收标准）的 CRUD，作为课时的子资源。
// criteria 是跨领域对接的原子单元：id/title 学习云直连，description 注册时快照归档（见 qtclass docs/dev-guide/provider.md）。

package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

type CriterionHandler struct {
	store       CriterionStorer
	lessonStore LessonStorer
	sceneStore  SceneStorer
}

func NewCriterionHandler(s CriterionStorer, ls LessonStorer, scs SceneStorer) *CriterionHandler {
	return &CriterionHandler{store: s, lessonStore: ls, sceneStore: scs}
}

func validateCri(c *domain.Criterion) string {
	if c.Title == "" || c.Description == "" {
		return "title and description are required"
	}
	return ""
}

// ListAll 全局列表：标准清单导出 / 快照注册管道的数据源。
// GET /criteria
func (h *CriterionHandler) ListAll(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

// ListByLesson 列出指定课时的所有验收标准。
// GET /lessons/{lessonId}/criteria
func (h *CriterionHandler) ListByLesson(w http.ResponseWriter, r *http.Request) {
	lessonID := r.PathValue("lessonId")
	if _, ok := h.lessonStore.Get(lessonID); !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, h.store.ListWhere("lessonId", lessonID))
}

// CreateByLesson 在指定课时下创建验收标准。title 全局唯一。
// POST /lessons/{lessonId}/criteria
func (h *CriterionHandler) CreateByLesson(w http.ResponseWriter, r *http.Request) {
	lessonID := r.PathValue("lessonId")
	if _, ok := h.lessonStore.Get(lessonID); !ok {
		http.Error(w, `{"error":"lesson not found"}`, http.StatusNotFound)
		return
	}
	h.create(w, r, lessonID, "")
}

// ListByScene 列出指定场景的验收标准（场景级）。
// GET /scenes/{sceneId}/criteria
func (h *CriterionHandler) ListByScene(w http.ResponseWriter, r *http.Request) {
	sceneID := r.PathValue("sceneId")
	writeJSON(w, http.StatusOK, h.store.ListWhere("sceneId", sceneID))
}

// CreateByScene 在指定场景下创建验收标准（场景级）：自动回填所属课时。
// POST /scenes/{sceneId}/criteria
func (h *CriterionHandler) CreateByScene(w http.ResponseWriter, r *http.Request) {
	sceneID := r.PathValue("sceneId")
	sc, ok := h.sceneStore.Get(sceneID)
	if !ok {
		http.Error(w, `{"error":"scene not found"}`, http.StatusNotFound)
		return
	}
	h.create(w, r, sc.LessonID, sc.ID)
}

// create 公共创建逻辑：校验字段 + title 唯一，归入 lesson/scene 归属后写入。
func (h *CriterionHandler) create(w http.ResponseWriter, r *http.Request, lessonID, sceneID string) {
	var c domain.Criterion
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := validateCri(&c); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	c.LessonID = lessonID
	c.SceneID = sceneID
	writeJSON(w, http.StatusCreated, h.store.Create(&c))
}

func (h *CriterionHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	c, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"criterion not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CriterionHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var c domain.Criterion
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := validateCri(&c); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	c.ID = id
	updated, ok := h.store.Update(&c)
	if !ok {
		http.Error(w, `{"error":"criterion not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *CriterionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"criterion not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
