package store

import "github.com/quanttide/qtcloud-course-provider/internal/domain"

// LessonStore 是 Lesson 的内存存储。
type LessonStore struct {
	*BaseStore[domain.Lesson]
}

func NewLessonStore() *LessonStore {
	return &LessonStore{BaseStore: NewBaseStore[domain.Lesson]("less")}
}

func (s *LessonStore) Create(l *domain.Lesson) *domain.Lesson {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *l
	clone.ID = s.nextID()
	clone.Slug = domain.MakeSlug(clone.Title, clone.ID)
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
