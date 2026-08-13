// 播放器数据适配 API：把课程结构（Lesson/Scene）转换为 qtclass 播放器格式
// （segments/pathSteps，与 assets/course.json 同构——数据源从客户端硬编码改为服务端）。

package handler

import (
	"encoding/json"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// PlayerData 播放器数据（对齐 qtclass studio 的 course.json 结构——
// segments/interactions 为按 id 索引的 Map，pathSteps/interactionNodes 为数组）。
type PlayerData struct {
	Title            string                   `json:"title"`
	Description      string                   `json:"description"`
	Objectives       []string                 `json:"objectives"`
	Segments         map[string]PlayerSegment `json:"segments"`
	PathSteps        []PlayerPathStep         `json:"pathSteps"`
	Interactions     map[string]json.RawMessage `json:"interactions"`
	InteractionNodes []json.RawMessage        `json:"interactionNodes"`
}

// PlayerSegment 播放片段（steps 展开为顺序片段）。
type PlayerSegment struct {
	ID        string  `json:"id"`
	SceneKey  string  `json:"sceneKey"`
	Duration  float64 `json:"duration"`
	Title     string  `json:"title"`
	Caption   string  `json:"caption"`
	Chapter   string  `json:"chapter"`
	PathStepID string  `json:"pathStepId"`
	Video     *string `json:"video,omitempty"`
	Next      string  `json:"next,omitempty"`
	Action    string  `json:"action,omitempty"`
}

// PlayerPathStep 侧边栏步骤。
type PlayerPathStep struct {
	ID    string `json:"id"`
	Title string `json:"title"`
	Type  string `json:"type"`
}

// PlayerHandler 播放器数据 API。
type PlayerHandler struct {
	programStore ProgramStorer
	courseStore  CourseStorer
	phaseStore   PhaseStorer
	lessonStore  LessonStorer
	sceneStore   SceneStorer
}

func NewPlayerHandler(ps ProgramStorer, cs CourseStorer, phs PhaseStorer, ls LessonStorer, ss SceneStorer) *PlayerHandler {
	return &PlayerHandler{programStore: ps, courseStore: cs, phaseStore: phs, lessonStore: ls, sceneStore: ss}
}

// Get 返回默认教程的播放器数据（首个 published Program 的课程结构）。
// GET /player-data
func (h *PlayerHandler) Get(w http.ResponseWriter, r *http.Request) {
	var prog *domain.Program
	for _, p := range h.programStore.List() {
		if p.Status == "published" {
			prog = p
			break
		}
	}
	if prog == nil || len(prog.CourseIDs) == 0 {
		http.Error(w, `{"error":"no published program"}`, http.StatusNotFound)
		return
	}
	course, ok := h.courseStore.Get(prog.CourseIDs[0])
	if !ok {
		http.Error(w, `{"error":"course not found"}`, http.StatusNotFound)
		return
	}

	data := PlayerData{
		Title:            course.Name,
		Description:      course.Description,
		Objectives:       []string{},
		Segments:         map[string]PlayerSegment{},
		Interactions:     map[string]json.RawMessage{},
		InteractionNodes: []json.RawMessage{},
	}

	// 课时 → pathSteps + segments
	for _, phase := range h.phaseStore.ListWhere("courseId", course.ID) {
		for _, lessonID := range phase.LessonIDs {
			lesson, ok := h.lessonStore.Get(lessonID)
			if !ok {
				continue
			}
			data.PathSteps = append(data.PathSteps, PlayerPathStep{
				ID:    lesson.ID,
				Title: lesson.Title,
				Type:  "lesson",
			})
			scenes := h.sceneStore.ListWhere("lessonId", lesson.ID)
			for i, sc := range scenes {
				seg := PlayerSegment{
					ID:         sc.ID,
					SceneKey:   sc.Slug,
					Duration:   15,
					Title:      sc.Title,
					Caption:    sc.VerifyTip,
					Chapter:    lesson.Title,
					PathStepID: lesson.ID,
				}
				if sc.VideoURL != "" {
					video := sc.VideoURL
					seg.Video = &video
				}
				if i < len(scenes)-1 {
					seg.Next = scenes[i+1].ID
				} else {
					seg.Action = "finish"
				}
				data.Segments[sc.ID] = seg
			}
		}
	}

	writeJSON(w, http.StatusOK, data)
}
