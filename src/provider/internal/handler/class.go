package handler

import (
	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// ClassHandler 提供 Class 的标准 CRUD。
type ClassHandler = CRUDHandler[domain.Class]

// NewClassHandler 创建 Class handler。
func NewClassHandler(s *store.ClassStore) *ClassHandler {
	return NewCRUDHandler(
		s,
		func(c *domain.Class) string {
			if c.Name == "" {
				return "name is required"
			}
			if c.RefID == "" {
				return "refId is required"
			}
			return ""
		},
		func(c *domain.Class, id string) { c.ID = id },
	).WithNameCheck(
		func(name string) string {
			if s.NameExists(name, func(c *domain.Class) string { return c.Name }) {
				return "name already exists"
			}
			return ""
		},
		func(c *domain.Class) string { return c.Name },
	)
}
