// 公开课程目录 API：学员端 /v1/courses 系列。
// 与管理 CRUD（/courses）分离：只读、按 qtclass 前端契约组装
// （Course { id,name,icon,badge,badgeClass,desc,meta,stages,status }）。
// status：open（可学习）/ locked（暂未开放，仅列表可见）。

package handler

import (
	"net/http"
	"sort"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// 展示字段默认值（对齐 qtclass course_list mock：icon/badge/badgeClass）。
var courseDisplay = map[string]struct {
	icon, badge, badgeClass string
}{
	"knowledge-work":   {"✍️", "知识工作", "beginner"},
	"vibe-coding":      {"💻", "氛围编程", "intermediate"},
	"big-data-intro":   {"📊", "大数据导论", "intermediate"},
	"data-engineering": {"🏗️", "数据工程", "advanced"},
	"prod":             {"🏭", "生产实习 · 微型创业", "capstone"},
}

func defaultIcon(id string) string {
	if d, ok := courseDisplay[id]; ok {
		return d.icon
	}
	return "📚"
}

func defaultBadge(id string) string {
	if d, ok := courseDisplay[id]; ok {
		return d.badge
	}
	return id
}

func defaultBadgeClass(id string) string {
	if d, ok := courseDisplay[id]; ok {
		return d.badgeClass
	}
	return "beginner"
}

// 课程展示顺序（对应产品 ①-⑤ 阶梯）。
var catalogOrder = map[string]int{
	"knowledge-work":   1,
	"vibe-coding":      2,
	"big-data-intro":   3,
	"data-engineering": 4,
	"prod":             5,
}

// CatalogLesson 课时条目（契约结构，duration 为展示文案）。
type CatalogLesson struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Duration string `json:"duration"` // 如 "10 min"
	Type     string `json:"type"`     // 阅读 / 视频 / 练习
}

// CatalogStage 模块（阶段）。
type CatalogStage struct {
	ID      string          `json:"id"`
	Name    string          `json:"name"`
	Lessons []CatalogLesson `json:"lessons"`
}

// CatalogMeta 课程元信息（duration 为展示文案，如 "2 周"）。
type CatalogMeta struct {
	Modules  int    `json:"modules"`
	Duration string `json:"duration"`
	Students int    `json:"students"`
}

// CatalogCourse 课程（qtclass 契约结构）。
type CatalogCourse struct {
	ID         string         `json:"id"`
	Name       string         `json:"name"`
	Icon       string         `json:"icon"`
	Badge      string         `json:"badge"`
	BadgeClass string         `json:"badgeClass"`
	Desc       string         `json:"desc"`
	Meta       CatalogMeta    `json:"meta"`
	Stages     []CatalogStage `json:"stages"`
	Status     string         `json:"status"` // "open" / "locked"
}

// CatalogHandler 公开课程目录。
type CatalogHandler struct {
	programStore ProgramStorer
	courseStore  CourseStorer
	phaseStore   PhaseStorer
	lessonStore  LessonStorer
}

func NewCatalogHandler(ps ProgramStorer, cs CourseStorer, phs PhaseStorer, ls LessonStorer) *CatalogHandler {
	return &CatalogHandler{programStore: ps, courseStore: cs, phaseStore: phs, lessonStore: ls}
}

// List GET /v1/courses：全部课程（含 locked，前端展示"暂未开放"），按阶梯顺序。
func (h *CatalogHandler) List(w http.ResponseWriter, r *http.Request) {
	courses := h.allCourses()
	if courses == nil {
		courses = []CatalogCourse{}
	}
	writeJSON(w, http.StatusOK, map[string]any{"courses": courses})
}

// Get GET /v1/courses/{id}：单课详情。
func (h *CatalogHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	course, ok := h.courseStore.Get(id)
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, h.build(course))
}

func (h *CatalogHandler) allCourses() []CatalogCourse {
	var out []CatalogCourse
	seen := map[string]bool{}
	for _, prog := range h.programStore.List() {
		if prog.Status != "published" {
			continue
		}
		for _, courseID := range prog.CourseIDs {
			if seen[courseID] {
				continue
			}
			course, ok := h.courseStore.Get(courseID)
			if !ok {
				continue
			}
			seen[courseID] = true
			out = append(out, h.build(course))
		}
	}
	// 按产品阶梯排序（知识工作① … 生产实习⑤）
	sort.SliceStable(out, func(i, j int) bool {
		return catalogOrder[out[i].ID] < catalogOrder[out[j].ID]
	})
	return out
}

func (h *CatalogHandler) build(c *domain.Course) CatalogCourse {
	stages := h.buildStages(c)
	status := "locked"
	if c.Status == "published" {
		status = "open"
	}
	return CatalogCourse{
		ID:         c.ID,
		Name:       c.Name,
		Icon:       defaultIcon(c.ID),
		Badge:      defaultBadge(c.ID),
		BadgeClass: defaultBadgeClass(c.ID),
		Desc:       c.Description,
		Meta: CatalogMeta{
			Modules:  len(stages),
			Duration: "2 周",
			Students: 38, // 原型展示值；真实统计后续版本接入
		},
		Stages: stages,
		Status: status,
	}
}

func (h *CatalogHandler) buildStages(c *domain.Course) []CatalogStage {
	phases := h.phaseStore.ListWhere("courseId", c.ID)
	// 按 SortOrder 排序（存储遍历无序，模块顺序由 SortOrder 保证）
	sort.SliceStable(phases, func(i, j int) bool {
		return phases[i].SortOrder < phases[j].SortOrder
	})
	var out []CatalogStage
	for _, phase := range phases {
		stage := CatalogStage{ID: phase.ID, Name: phase.Name}
		for _, lessonID := range phase.LessonIDs {
			lesson, ok := h.lessonStore.Get(lessonID)
			if !ok {
				continue
			}
			stage.Lessons = append(stage.Lessons, CatalogLesson{
				ID:       lesson.ID,
				Title:    lesson.Title,
				Duration: "10 min",
				Type:     "阅读",
			})
		}
		out = append(out, stage)
	}
	return out
}
