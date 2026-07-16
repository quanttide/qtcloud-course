package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// CourseStore 是 Course 的内存存储。
type CourseStore struct {
	*BaseStore[domain.Course]
}

func NewCourseStore() *CourseStore {
	return &CourseStore{BaseStore: NewBaseStore[domain.Course]("cour")}
}

func (s *CourseStore) Create(c *domain.Course) *domain.Course {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *c
	clone.ID = s.nextID()
	clone.Slug = domain.MakeSlug(clone.Name, clone.ID)
	s.data[clone.ID] = &clone
	return &clone
}

func (s *CourseStore) Update(c *domain.Course) (*domain.Course, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[c.ID]
	if !ok {
		return nil, false
	}
	existing.Name = c.Name
	existing.Description = c.Description
	existing.Status = c.Status
	return existing, true
}
