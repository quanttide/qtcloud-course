package store

import (
	"fmt"
	"sync"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
)

// ProgramStore 是 Program 的内存存储。
type ProgramStore struct {
	mu     sync.RWMutex
	data   map[string]*domain.Program
	nextID int
}

// NewProgramStore 创建 ProgramStore。
func NewProgramStore() *ProgramStore {
	return &ProgramStore{
		data:   make(map[string]*domain.Program),
		nextID: 1,
	}
}

func (s *ProgramStore) nextProgramID() string {
	id := fmt.Sprintf("prog-%d", s.nextID)
	s.nextID++
	return id
}

func (s *ProgramStore) nextCourseID() string {
	id := fmt.Sprintf("cour-%d", s.nextID)
	s.nextID++
	return id
}

func (s *ProgramStore) nextLessonID() string {
	id := fmt.Sprintf("less-%d", s.nextID)
	s.nextID++
	return id
}

// List 返回所有 Program。
func (s *ProgramStore) List() []*domain.Program {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*domain.Program, 0, len(s.data))
	for _, p := range s.data {
		result = append(result, p)
	}
	return result
}

// Get 根据 ID 获取 Program。
func (s *ProgramStore) Get(id string) (*domain.Program, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[id]
	return p, ok
}

// Create 创建 Program。
func (s *ProgramStore) Create(p *domain.Program) *domain.Program {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *p
	clone.ID = s.nextProgramID()
	clone.Courses = make([]domain.Course, len(p.Courses))
	for i, c := range p.Courses {
		c.ID = s.nextCourseID()
		clone.Courses[i] = c
	}
	s.data[clone.ID] = &clone
	return &clone
}

// Update 更新 Program。
func (s *ProgramStore) Update(p *domain.Program) (*domain.Program, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[p.ID]
	if !ok {
		return nil, false
	}
	// 保留原始 Courses，只更新顶层字段
	existing.Name = p.Name
	existing.Description = p.Description
	existing.Status = p.Status
	return existing, true
}

// Delete 删除 Program。
func (s *ProgramStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}

// --- Course 操作 ---

// ListCourses 返回 Program 下的所有 Course。
func (s *ProgramStore) ListCourses(programID string) ([]domain.Course, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	result := make([]domain.Course, len(p.Courses))
	copy(result, p.Courses)
	return result, true
}

// GetCourse 获取 Program 下的指定 Course。
func (s *ProgramStore) GetCourse(programID, courseID string) (*domain.Course, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == courseID {
			return &p.Courses[i], true
		}
	}
	return nil, false
}

// CreateCourse 在 Program 下创建 Course。
func (s *ProgramStore) CreateCourse(programID string, c *domain.Course) (*domain.Course, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	clone := *c
	clone.ID = s.nextCourseID()
	clone.Lessons = make([]domain.Lesson, len(c.Lessons))
	for i, l := range c.Lessons {
		l.ID = s.nextLessonID()
		clone.Lessons[i] = l
	}
	p.Courses = append(p.Courses, clone)
	return &clone, true
}

// UpdateCourse 更新 Course。
func (s *ProgramStore) UpdateCourse(programID string, c *domain.Course) (*domain.Course, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == c.ID {
			p.Courses[i].Name = c.Name
			p.Courses[i].Description = c.Description
			p.Courses[i].Status = c.Status
			return &p.Courses[i], true
		}
	}
	return nil, false
}

// DeleteCourse 删除 Course。
func (s *ProgramStore) DeleteCourse(programID, courseID string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == courseID {
			p.Courses = append(p.Courses[:i], p.Courses[i+1:]...)
			return true
		}
	}
	return false
}

// --- Lesson 操作 ---

// ListLessons 返回 Course 下的所有 Lesson。
func (s *ProgramStore) ListLessons(programID, courseID string) ([]domain.Lesson, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for _, c := range p.Courses {
		if c.ID == courseID {
			result := make([]domain.Lesson, len(c.Lessons))
			copy(result, c.Lessons)
			return result, true
		}
	}
	return nil, false
}

// GetLesson 获取指定 Lesson。
func (s *ProgramStore) GetLesson(programID, courseID, lessonID string) (*domain.Lesson, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for _, c := range p.Courses {
		if c.ID == courseID {
			for _, l := range c.Lessons {
				if l.ID == lessonID {
					return &l, true
				}
			}
		}
	}
	return nil, false
}

// CreateLesson 在 Course 下创建 Lesson。
func (s *ProgramStore) CreateLesson(programID, courseID string, l *domain.Lesson) (*domain.Lesson, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == courseID {
			clone := *l
			clone.ID = s.nextLessonID()
			p.Courses[i].Lessons = append(p.Courses[i].Lessons, clone)
			return &clone, true
		}
	}
	return nil, false
}

// UpdateLesson 更新 Lesson。
func (s *ProgramStore) UpdateLesson(programID, courseID string, l *domain.Lesson) (*domain.Lesson, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return nil, false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == courseID {
			for j := range p.Courses[i].Lessons {
				if p.Courses[i].Lessons[j].ID == l.ID {
					p.Courses[i].Lessons[j].Title = l.Title
					p.Courses[i].Lessons[j].Description = l.Description
					p.Courses[i].Lessons[j].Duration = l.Duration
					p.Courses[i].Lessons[j].Status = l.Status
					return &p.Courses[i].Lessons[j], true
				}
			}
		}
	}
	return nil, false
}

// DeleteLesson 删除 Lesson。
func (s *ProgramStore) DeleteLesson(programID, courseID, lessonID string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	p, ok := s.data[programID]
	if !ok {
		return false
	}
	for i := range p.Courses {
		if p.Courses[i].ID == courseID {
			for j := range p.Courses[i].Lessons {
				if p.Courses[i].Lessons[j].ID == lessonID {
					p.Courses[i].Lessons = append(p.Courses[i].Lessons[:j], p.Courses[i].Lessons[j+1:]...)
					return true
				}
			}
		}
	}
	return false
}
