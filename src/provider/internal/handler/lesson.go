package handler

import (
	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// LessonHandler 提供 Lesson 的标准 CRUD。
type LessonHandler = CRUDHandler[domain.Lesson]

// NewLessonHandler 创建 Lesson handler。
func NewLessonHandler(s *store.LessonStore) *LessonHandler {
	return NewCRUDHandler(
		s,
		func(l *domain.Lesson) string {
			if l.Title == "" {
				return "title is required"
			}
			return ""
		},
		func(l *domain.Lesson, id string) { l.ID = id },
	).WithNameCheck(
		func(name string) string {
			if s.NameExists(name, func(l *domain.Lesson) string { return l.Title }) {
				return "name already exists"
			}
			return ""
		},
		func(l *domain.Lesson) string { return l.Title },
	)
}
