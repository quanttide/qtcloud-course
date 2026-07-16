// Package domain 定义课程单位子领域的核心数据模型。
package domain

// Program 是专业，顶层教学计划。
type Program struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Slug        string   `json:"slug"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
	CourseIDs   []string `json:"courseIds"`         // 引用的课程 ID 列表
}

// Course 是课程，教学单元。可被多个 Program 引用。
type Course struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Slug        string   `json:"slug"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
}

// Phase 是阶段，课程的中间组织层。
// 示例："数据工程"课程可分为"数据采集阶段"、"数据清洗阶段"、"数据分析阶段"。
type Phase struct {
	ID          string   `json:"id"`
	CourseID    string   `json:"courseId"`            // 所属课程
	Name        string   `json:"name"`
	Slug        string   `json:"slug"`
	Description string   `json:"description,omitempty"`
	SortOrder   int      `json:"sortOrder,omitempty"`   // 排序序号
	LessonIDs   []string `json:"lessonIds"`              // 引用的课时 ID 列表
}

// Lesson 是课时，教学内容的最小组织单元。可被多个 Phase 引用。
type Lesson struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Slug         string `json:"slug"`
	Description  string `json:"description,omitempty"`
	Duration     int    `json:"duration,omitempty"` // 课时时长（分钟），默认45
	Status       string `json:"status,omitempty"`   // "draft" / "published"
	StartSceneID string `json:"startSceneId,omitempty"` // 入口场景 ID
}

// Scene 是视频片段，互动课时的基本单元。
type Scene struct {
	ID         string   `json:"id"`
	LessonID   string   `json:"lessonId"`           // 所属课时
	Title      string   `json:"title,omitempty"`      // 场景标题
	Slug       string   `json:"slug"`
	VideoURL   string   `json:"videoUrl"`            // 本段视频地址
	Steps      []Step   `json:"steps,omitempty"`       // 操作步骤列表
	VerifyTip  string   `json:"verifyTip,omitempty"`  // 验证方式
	Choices    []Choice `json:"choices"`                // 分支选项（空数组表示终结）
}

// Step 是场景内的操作步骤。
type Step struct {
	Order    int    `json:"order"`
	Content  string `json:"content"`
}

// Choice 是场景内的分支选项，用户选择后跳转到目标场景。
type Choice struct {
	Label         string `json:"label"`
	TargetSceneID string `json:"targetSceneId"`
}
