package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// ProgramStore 是 Program 的内存存储。
type ProgramStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Program
	seq  int
}

func NewProgramStore() *ProgramStore {
	return &ProgramStore{
		data: make(map[string]*domain.Program),
		seq:  1,
	}
}

func (s *ProgramStore) nextID() string {
	id := fmt.Sprintf("prog-%d", s.seq)
	s.seq++
	return id
}

func (s *ProgramStore) List() []*domain.Program {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Program, 0, len(s.data))
	for _, p := range s.data {
		result = append(result, p)
	}
	return result
}

func (s *ProgramStore) Get(id string) (*domain.Program, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[id]
	return p, ok
}

func (s *ProgramStore) Create(p *domain.Program) *domain.Program {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *p
	clone.ID = s.nextID()
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

func (s *ProgramStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
