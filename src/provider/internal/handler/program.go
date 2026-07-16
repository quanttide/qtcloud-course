package handler

import (
	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// ProgramHandler 提供 Program 的标准 CRUD。
type ProgramHandler = CRUDHandler[domain.Program]

// NewProgramHandler 创建 Program handler。
// nameChecker 通过 WithNameCheck 可选启用。
func NewProgramHandler(s *store.ProgramStore) *ProgramHandler {
	return NewCRUDHandler(
		s,
		func(p *domain.Program) string {
			if p.Name == "" {
				return "name is required"
			}
			return ""
		},
		func(p *domain.Program, id string) { p.ID = id },
	).WithNameCheck(
		func(name string) string {
			if s.NameExists(name, func(p *domain.Program) string { return p.Name }) {
				return "name already exists"
			}
			return ""
		},
		func(p *domain.Program) string { return p.Name },
	)
}
