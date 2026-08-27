// Package domain 定义课程领域的核心数据模型。
//
// 模型单一事实源在 quanttide-course-toolkit（packages/go），
// 本包以类型别名复用并保持服务端 API 标签一致；
// 课程树三级结构：Course → Lesson → Scene。
package domain

import course "github.com/quanttide/quanttide-course-toolkit/packages/go/pkg"

type (
	// Course 是课程，教学单元。学员端目录直接展示课程。
	Course = course.Course
	// Lesson 是课时，教学内容的最小组织单元。归属课程。
	Lesson = course.Lesson
	// Scene 是视频片段，互动课时的基本单元。
	Scene = course.Scene
	// Criterion 是验收标准：课程研发阶段定义，跨领域对接的原子单元。
	// 学习云完成记录的 criterion_id 直指本实体 ID。
	Criterion = course.Criterion
	// Step 是场景内的操作步骤。
	Step = course.Step
	// Choice 是场景内的分支选项，用户选择后跳转到目标场景。
	Choice = course.Choice
)
