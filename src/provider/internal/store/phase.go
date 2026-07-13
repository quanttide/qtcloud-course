package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

type PhaseStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Phase
	seq  int
}

func NewPhaseStore() *PhaseStore {
	return &PhaseStore{
		data: make(map[string]*domain.Phase),
		seq:  1,
	}
}

func (s *PhaseStore) nextID() string {
	id := fmt.Sprintf("phase-%d", s.seq)
	s.seq++
	return id
}

func (s *PhaseStore) List() []*domain.Phase {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Phase, 0, len(s.data))
	for _, p := range s.data {
		result = append(result, p)
	}
	return result
}

func (s *PhaseStore) ListByCourse(courseID string) []*domain.Phase {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var result []*domain.Phase
	for _, p := range s.data {
		if p.CourseID == courseID {
			result = append(result, p)
		}
	}
	return result
}

func (s *PhaseStore) Get(id string) (*domain.Phase, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[id]
	return p, ok
}

func (s *PhaseStore) Create(p *domain.Phase) *domain.Phase {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *p
	clone.ID = s.nextID()
	if clone.LessonIDs == nil {
		clone.LessonIDs = []string{}
	}
	s.data[clone.ID] = &clone
	return &clone
}

func (s *PhaseStore) Update(p *domain.Phase) (*domain.Phase, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[p.ID]
	if !ok {
		return nil, false
	}
	existing.Name = p.Name
	existing.Description = p.Description
	existing.SortOrder = p.SortOrder
	existing.LessonIDs = p.LessonIDs
	return existing, true
}

func (s *PhaseStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
