package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// CourseStore 是 Course 的内存存储。
type CourseStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Course
	seq  int
}

func NewCourseStore() *CourseStore {
	return &CourseStore{
		data: make(map[string]*domain.Course),
		seq:  1,
	}
}

func (s *CourseStore) nextID() string {
	id := fmt.Sprintf("cour-%d", s.seq)
	s.seq++
	return id
}

func (s *CourseStore) List() []*domain.Course {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Course, 0, len(s.data))
	for _, c := range s.data {
		result = append(result, c)
	}
	return result
}

func (s *CourseStore) Get(id string) (*domain.Course, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	c, ok := s.data[id]
	return c, ok
}

func (s *CourseStore) Create(c *domain.Course) *domain.Course {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *c
	clone.ID = s.nextID()
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

func (s *CourseStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
