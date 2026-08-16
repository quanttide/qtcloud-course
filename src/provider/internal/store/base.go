package store

import (
	"encoding/json"
	"fmt"
	"reflect"
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

// ── 通用写入（持久化版 SQLiteStore 使用；内存 store 保留各自定制的 Create/Update） ──
// 泛型无法直接访问字段，统一走 JSON map 操作 ID。

// create 通用创建：ID 生成 + 存入。
func (s *BaseStore[T]) create(v *T) *T {
	s.mu.Lock()
	defer s.mu.Unlock()
	raw, _ := json.Marshal(v)
	var m map[string]any
	_ = json.Unmarshal(raw, &m)
	id := s.nextID()
	m["id"] = id
	merged, _ := json.Marshal(m)
	var clone T
	_ = json.Unmarshal(merged, &clone)
	s.data[id] = &clone
	return &clone
}

// update 通用更新：整体替换（保留原 ID）。
func (s *BaseStore[T]) update(v *T) (*T, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	oldID := idOf(v)
	if _, ok := s.data[oldID]; !ok {
		return nil, false
	}
	raw, _ := json.Marshal(v)
	var m map[string]any
	_ = json.Unmarshal(raw, &m)
	m["id"] = oldID
	merged, _ := json.Marshal(m)
	var clone T
	_ = json.Unmarshal(merged, &clone)
	s.data[oldID] = &clone
	return &clone, true
}

// delete 通用删除。
func (s *BaseStore[T]) delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.data[id]; !ok {
		return false
	}
	delete(s.data, id)
	return true
}

// idOf 通过 JSON 提取 ID（domain 类型均含 id 字段）。
func idOf[T any](v *T) string {
	raw, _ := json.Marshal(v)
	var m map[string]any
	if json.Unmarshal(raw, &m) == nil {
		if id, ok := m["id"].(string); ok {
			return id
		}
	}
	return ""
}

// SetID 改写实体 ID 并迁移存储 key（seed 固定 ID 用，如生产实习课程 id=prod；
// 常规 Create/Update 不暴露 ID 覆盖，避免管理端误用）。
func (s *BaseStore[T]) SetID(v *T, newID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if oldID := idOf(v); oldID != "" && oldID != newID {
		delete(s.data, oldID)
	}
	rv := reflect.ValueOf(v).Elem()
	if f := rv.FieldByName("ID"); f.CanSet() {
		f.SetString(newID)
	}
	s.data[newID] = v
}

// ListWhere 按 JSON 字段过滤（如 ListWhere("courseId", "cour-1")）。
func (s *BaseStore[T]) ListWhere(field, value string) []*T {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*T
	for _, v := range s.data {
		raw, _ := json.Marshal(v)
		var m map[string]any
		if json.Unmarshal(raw, &m) == nil {
			if got, ok := m[field].(string); ok && got == value {
				out = append(out, v)
			}
		}
	}
	return out
}
