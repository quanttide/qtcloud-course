package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// ClassStore 是 Class 的内存存储。
type ClassStore struct {
	*BaseStore[domain.Class]
}

func NewClassStore() *ClassStore {
	return &ClassStore{BaseStore: NewBaseStore[domain.Class]("class")}
}

func (s *ClassStore) Create(c *domain.Class) *domain.Class {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *c
	clone.ID = s.nextID()
	clone.Slug = domain.MakeSlug(clone.Name, clone.ID)
	s.data[clone.ID] = &clone
	return &clone
}

func (s *ClassStore) Update(c *domain.Class) (*domain.Class, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[c.ID]
	if !ok {
		return nil, false
	}
	existing.Name = c.Name
	existing.RefName = c.RefName
	existing.RefType = c.RefType
	existing.RefID = c.RefID
	existing.Status = c.Status
	existing.StartDate = c.StartDate
	existing.EndDate = c.EndDate
	existing.StudentCount = c.StudentCount
	existing.Progress = c.Progress
	return existing, true
}
