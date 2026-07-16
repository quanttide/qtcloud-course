package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// ProgramStore 是 Program 的内存存储。
type ProgramStore struct {
	*BaseStore[domain.Program]
}

func NewProgramStore() *ProgramStore {
	return &ProgramStore{BaseStore: NewBaseStore[domain.Program]("prog")}
}

func (s *ProgramStore) Create(p *domain.Program) *domain.Program {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *p
	clone.ID = s.nextID()
	clone.Slug = domain.MakeSlug(clone.Name, clone.ID)
	if clone.CourseIDs == nil {
		clone.CourseIDs = []string{}
	}
	s.data[clone.ID] = &clone
	return &clone
}

func (s *ProgramStore) Update(p *domain.Program) (*domain.Program, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[p.ID]
	if !ok {
		return nil, false
	}
	existing.Name = p.Name
	existing.Description = p.Description
	existing.Status = p.Status
	existing.CourseIDs = p.CourseIDs
	return existing, true
}
