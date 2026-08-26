package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// CriterionStore 是 Criterion（验收标准）的内存存储。
// id 学习云直连，description 为课程侧事实源；无 slug（title 即标准名称）。
type CriterionStore struct {
	*BaseStore[domain.Criterion]
}

func NewCriterionStore() *CriterionStore {
	return &CriterionStore{BaseStore: NewBaseStore[domain.Criterion]("cri")}
}

func (s *CriterionStore) Create(c *domain.Criterion) *domain.Criterion {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *c
	clone.ID = s.nextID()
	s.data[clone.ID] = &clone
	return &clone
}

func (s *CriterionStore) Update(c *domain.Criterion) (*domain.Criterion, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.data[c.ID]; !ok {
		return nil, false
	}
	clone := *c
	s.data[clone.ID] = &clone
	return &clone, true
}
