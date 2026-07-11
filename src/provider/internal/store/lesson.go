package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// LessonStore 是 Lesson 的内存存储。
type LessonStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Lesson
	seq  int
}

func NewLessonStore() *LessonStore {
	return &LessonStore{
		data: make(map[string]*domain.Lesson),
		seq:  1,
	}
}

func (s *LessonStore) nextID() string {
	id := fmt.Sprintf("less-%d", s.seq)
	s.seq++
	return id
}

func (s *LessonStore) List() []*domain.Lesson {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Lesson, 0, len(s.data))
	for _, l := range s.data {
		result = append(result, l)
	}
	return result
}

func (s *LessonStore) Get(id string) (*domain.Lesson, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	l, ok := s.data[id]
	return l, ok
}

func (s *LessonStore) Create(l *domain.Lesson) *domain.Lesson {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *l
	clone.ID = s.nextID()
	s.data[clone.ID] = &clone
	return &clone
}

func (s *LessonStore) Update(l *domain.Lesson) (*domain.Lesson, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[l.ID]
	if !ok {
		return nil, false
	}
	existing.Title = l.Title
	existing.Description = l.Description
	existing.Duration = l.Duration
	existing.Status = l.Status
	existing.StartSceneID = l.StartSceneID
	return existing, true
}

func (s *LessonStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
