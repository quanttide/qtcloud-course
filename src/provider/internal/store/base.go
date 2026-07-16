package store

import (
	"fmt"
	"sync"
)

// BaseStore 提供通用的内存存储骨架：List/Get/Delete 和 ID 生成。
// 具体类型嵌入后只需实现 Create/Update（因字段各异）。
type BaseStore[T any] struct {
	mu       sync.RWMutex
	data     map[string]*T
	seq      int
	idPrefix string
}

// NewBaseStore 创建泛型存储。
func NewBaseStore[T any](idPrefix string) *BaseStore[T] {
	return &BaseStore[T]{
		data:     make(map[string]*T),
		seq:      1,
		idPrefix: idPrefix,
	}
}

// nextID 生成自增 ID，如 "prog-1"、"cour-2"。
func (s *BaseStore[T]) nextID() string {
	id := fmt.Sprintf("%s-%d", s.idPrefix, s.seq)
	s.seq++
	return id
}

// List 返回全部实体。
func (s *BaseStore[T]) List() []*T {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make([]*T, 0, len(s.data))
	for _, v := range s.data {
		result = append(result, v)
	}
	return result
}

// Get 按 ID 查找实体。
func (s *BaseStore[T]) Get(id string) (*T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.data[id]
	return v, ok
}

// Delete 按 ID 删除实体。
func (s *BaseStore[T]) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.data[id]
	if ok {
		delete(s.data, id)
	}
	return ok
}

// NameExists 检查 name 是否已被占用。
func (s *BaseStore[T]) NameExists(name string, getName func(*T) string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, v := range s.data {
		if getName(v) == name {
			return true
		}
	}
	return false
}
