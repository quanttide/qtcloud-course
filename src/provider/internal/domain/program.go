// Package domain 定义课程单位子领域的核心数据模型。
package domain

// Program 是专业，顶层教学计划。
type Program struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
	Courses     []Course `json:"courses"`
}

// Course 是课程，教学单元。
type Course struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Status      string   `json:"status,omitempty"` // "draft" / "published"
	Lessons     []Lesson `json:"lessons,omitempty"`
}

// Lesson 是课时，教学内容的最小组织单元。
type Lesson struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
	Duration    int    `json:"duration,omitempty"` // 课时时长（分钟），默认45
	Status      string `json:"status,omitempty"`   // "draft" / "published"
}
