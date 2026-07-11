// Package domain 定义课程单位子领域的核心数据模型。
package domain

// Program 是专业，顶层教学计划。
type Program struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
	CourseIDs   []string `json:"courseIds"`         // 引用的课程 ID 列表
}

// Course 是课程，教学单元。可被多个 Program 引用。
type Course struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
	LessonIDs   []string `json:"lessonIds"`         // 引用的课时 ID 列表
}

// Lesson 是课时，教学内容的最小组织单元。可被多个 Course 引用。
type Lesson struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Description  string `json:"description,omitempty"`
	Duration     int    `json:"duration,omitempty"` // 课时时长（分钟），默认45
	Status       string `json:"status,omitempty"`   // "draft" / "published"
	StartSceneID string `json:"startSceneId,omitempty"` // 入口场景 ID
}

// Scene 是视频片段，互动课时的基本单元。
type Scene struct {
	ID       string   `json:"id"`
	LessonID string   `json:"lessonId"`           // 所属课时
	VideoURL string   `json:"videoUrl"`            // 本段视频地址
	Choices  []Choice `json:"choices"`                // 分支选项（空数组表示终结）
}

// Choice 是场景内的分支选项，用户选择后跳转到目标场景。
type Choice struct {
	Label         string `json:"label"`
	TargetSceneID string `json:"targetSceneId"`
}
