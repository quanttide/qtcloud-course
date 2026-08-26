// 课程资源读入口：返回内容实体本身，不做任何前端视图适配。
// 展示层组装（目录卡片、播放器 segments 等）属应用侧职责（见 qtclass src/provider）。

package handler

import (
	"net/http"
	"sort"
)

// CourseReadHandler 提供课程的读入口（与写操作同一路由面）。
type CourseReadHandler struct {
	courseStore CourseStorer
}

func NewCourseReadHandler(cs CourseStorer) *CourseReadHandler {
	return &CourseReadHandler{courseStore: cs}
}

// List GET /courses：全部课程实体，按 SortOrder 排序。
func (h *CourseReadHandler) List(w http.ResponseWriter, r *http.Request) {
	courses := h.courseStore.List()
	sort.SliceStable(courses, func(i, j int) bool {
		return courses[i].SortOrder < courses[j].SortOrder
	})
	writeJSON(w, http.StatusOK, courses)
}

// Get GET /courses/{id}：单课详情（原始实体）。
func (h *CourseReadHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	course, ok := h.courseStore.Get(id)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, course)
}
