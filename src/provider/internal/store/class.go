package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// ClassStore 是 Class 的内存存储。
type ClassStore struct {
	mu     sync.RWMutex
	data   map[string]*domain.Class
	idSeq int
}

// NewClassStore 创建 ClassStore。
func NewClassStore() *ClassStore {
	return &ClassStore{
		data:   make(map[string]*domain.Class),
		idSeq: 1,
	}
}

func (s *ClassStore) nextID() string {
	id := fmt.Sprintf("class-%d", s.idSeq)
	s.idSeq++
	return id
}

// List 返回所有 Class。
func (s *ClassStore) List() []*domain.Class {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Class, 0, len(s.data))
	for _, c := range s.data {
		result = append(result, c)
	}
	return result
}

// Get 根据 ID 获取 Class。
func (s *ClassStore) Get(id string) (*domain.Class, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	c, ok := s.data[id]
	return c, ok
}

// Create 创建 Class。
func (s *ClassStore) Create(c *domain.Class) *domain.Class {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *c
	clone.ID = s.nextID()
	s.data[clone.ID] = &clone
	return &clone
}

// Update 更新 Class。
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

// Delete 删除 Class。
func (s *ClassStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
