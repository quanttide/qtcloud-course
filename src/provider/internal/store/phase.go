package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// PhaseStore 是 Phase 的内存存储。
type PhaseStore struct {
	*BaseStore[domain.Phase]
}

func NewPhaseStore() *PhaseStore {
	return &PhaseStore{BaseStore: NewBaseStore[domain.Phase]("phase")}
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

func (s *PhaseStore) Create(p *domain.Phase) *domain.Phase {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *p
	clone.ID = s.nextID()
	clone.Slug = domain.MakeSlug(clone.Name, clone.ID)
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
