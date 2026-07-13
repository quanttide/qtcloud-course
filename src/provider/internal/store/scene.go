package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// SceneStore 是 Scene 的内存存储。
type SceneStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Scene
	seq  int
}

func NewSceneStore() *SceneStore {
	return &SceneStore{
		data: make(map[string]*domain.Scene),
		seq:  1,
	}
}

func (s *SceneStore) nextID() string {
	id := fmt.Sprintf("scene-%d", s.seq)
	s.seq++
	return id
}

func (s *SceneStore) List(lessonID string) []*domain.Scene {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var result []*domain.Scene
	for _, sc := range s.data {
		if sc.LessonID == lessonID {
			result = append(result, sc)
		}
	}
	return result
}

func (s *SceneStore) Get(id string) (*domain.Scene, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	sc, ok := s.data[id]
	return sc, ok
}

func (s *SceneStore) Create(sc *domain.Scene) *domain.Scene {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *sc
	clone.ID = s.nextID()
	if clone.Choices == nil {
		clone.Choices = []domain.Choice{}
	}
	s.data[clone.ID] = &clone
	return &clone
}

func (s *SceneStore) Update(sc *domain.Scene) (*domain.Scene, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[sc.ID]
	if !ok {
		return nil, false
	}
	existing.VideoURL = sc.VideoURL
	existing.Choices = sc.Choices
	existing.Title = sc.Title
	existing.Steps = sc.Steps
	existing.VerifyTip = sc.VerifyTip
	return existing, true
}

func (s *SceneStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}
