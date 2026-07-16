package handler

import (
	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// CourseHandler 提供 Course 的标准 CRUD。
type CourseHandler = CRUDHandler[domain.Course]

// NewCourseHandler 创建 Course handler。
func NewCourseHandler(s *store.CourseStore) *CourseHandler {
	return NewCRUDHandler(
		s,
		func(c *domain.Course) string {
			if c.Name == "" {
				return "name is required"
			}
			return ""
		},
		func(c *domain.Course, id string) { c.ID = id },
	).WithNameCheck(
		func(name string) string {
			if s.NameExists(name, func(c *domain.Course) string { return c.Name }) {
				return "name already exists"
			}
			return ""
		},
		func(c *domain.Course) string { return c.Name },
	)
}
