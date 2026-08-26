// Package domain 定义课程领域的核心数据模型。
// 课程树三级结构：Course → Lesson → Scene。
package domain

// Course 是课程，教学单元。学员端目录直接展示课程。
type Course struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Slug        string `json:"slug"`
	Description string `json:"description,omitempty"`
	Status      string `json:"status,omitempty"`    // "draft" / "published"
	SortOrder   int    `json:"sortOrder,omitempty"` // 排序序号（目录阶梯顺序）
}

// Lesson 是课时，教学内容的最小组织单元。归属课程。
type Lesson struct {
	ID           string `json:"id"`
	CourseID     string `json:"courseId"` // 所属课程
	Title        string `json:"title"`
	Slug         string `json:"slug"`
	Description  string `json:"description,omitempty"`
	Duration     int    `json:"duration,omitempty"`     // 课时时长（分钟），默认45
	SortOrder    int    `json:"sortOrder,omitempty"`    // 排序序号（课时顺序）
	Status       string `json:"status,omitempty"`       // "draft" / "published"
	StartSceneID string `json:"startSceneId,omitempty"` // 入口场景 ID
	// Criteria 引用课时总验收标准（场景全过 + 跨场景约束，如安全/合规）。
	Criteria []string `json:"criteria,omitempty"`
}

// Scene 是视频片段，互动课时的基本单元。
type Scene struct {
	ID        string   `json:"id"`
	LessonID  string   `json:"lessonId"`        // 所属课时
	Title     string   `json:"title,omitempty"` // 场景标题
	Slug      string   `json:"slug"`
	VideoURL  string   `json:"videoUrl"`            // 本段视频地址
	Steps     []Step   `json:"steps,omitempty"`     // 操作步骤列表
	VerifyTip string   `json:"verifyTip,omitempty"` // 验证方式
	Choices   []Choice `json:"choices"`             // 分支选项（空数组表示终结）
	// Criteria 引用本场景完成的验收标准（每步判定——与课时级同构，
	// 课时总验收 = 场景全过 + 跨场景约束）。
	Criteria []string `json:"criteria,omitempty"`
}

// Criterion 是验收标准：课程研发阶段定义，跨领域对接的原子单元。
// 与学习云（qtcloud-learn）同构：id/title 同源直连，description 注册时快照归档；
// 单一事实源在本领域，学习云不感知课程树。
type Criterion struct {
	ID          string `json:"id"`
	LessonID    string `json:"lessonId"`          // 所属课时
	SceneID     string `json:"sceneId,omitempty"` // 所属场景（场景级验收标准；空表示课时级）
	Title       string `json:"title"`             // 标准名称（人类可读，用于展示与检索）
	Description string `json:"description"`       // 判定规则（什么算做对）
}

// Step 是场景内的操作步骤。
type Step struct {
	Order   int    `json:"order"`
	Content string `json:"content"`
}

// Choice 是场景内的分支选项，用户选择后跳转到目标场景。
type Choice struct {
	Label         string `json:"label"`
	TargetSceneID string `json:"targetSceneId"`
}
