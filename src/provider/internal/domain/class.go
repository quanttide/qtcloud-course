package domain

// Class 是教学单位，学员共同学习的组织。
type Class struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	Slug         string  `json:"slug"`
	RefName      string  `json:"refName"`                 // 引用的专业/课程名称（展示用）
	RefType      string  `json:"refType,omitempty"`       // 引用类型："program" / "course"
	RefID        string  `json:"refId"`                   // 引用的 Program/Course ID
	Status       string  `json:"status,omitempty"`        // "preparing" / "active" / "ended"
	StartDate    string  `json:"startDate"`              // ISO 日期
	EndDate      string  `json:"endDate"`                // ISO 日期
	StudentCount int     `json:"studentCount,omitempty"`  // 学员数
	Progress     float64 `json:"progress,omitempty"`      // 教学进度（0.0 ~ 1.0）
}
