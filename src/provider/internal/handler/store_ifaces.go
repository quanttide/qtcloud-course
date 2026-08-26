// 存储接口：handler 依赖接口而非具体类型（内存/OSS 实现可互换）。
package handler

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// NameChecker 提供 name 重复校验（内存与 OSS 均嵌入 BaseStore 实现）。
type NameChecker[T any] interface {
	NameExists(name string, getName func(*T) string) bool
}

// CourseStorer 是 CourseHandler 所需存储。
type CourseStorer interface {
	CRUDStore[domain.Course]
	NameExists(name string, getName func(*domain.Course) string) bool
}

// LessonStorer 是 LessonHandler 所需存储。
type LessonStorer interface {
	CRUDStore[domain.Lesson]
	NameExists(name string, getName func(*domain.Lesson) string) bool
	ListWhere(field, value string) []*domain.Lesson
}

// SceneStorer 是 SceneHandler 所需存储。
type SceneStorer interface {
	CRUDStore[domain.Scene]
	ListWhere(field, value string) []*domain.Scene
}

// CriterionStorer 是 CriterionHandler 所需存储。
type CriterionStorer interface {
	CRUDStore[domain.Criterion]
	NameExists(name string, getName func(*domain.Criterion) string) bool
	ListWhere(field, value string) []*domain.Criterion
}
