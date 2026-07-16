package handler

import (
	"encoding/json"
	"net/http"
)

// CRUDStore 是泛型处理器所需的存储接口。
type CRUDStore[T any] interface {
	List() []*T
	Get(string) (*T, bool)
	Create(*T) *T
	Update(*T) (*T, bool)
	Delete(string) bool
}

// CRUDHandler 提供标准 CRUD HTTP handler，适合无特殊校验的资源。
type CRUDHandler[T any] struct {
	store       CRUDStore[T]
	validateFn  func(*T) string     // 返回空串表示合法，否则返回错误消息
	setIDFn     func(*T, string)    // 设置实体 ID（从路径取值）
	nameChecker func(string) string // 可选：返回空串表示可用，否则返回冲突消息
	getNameFn   func(*T) string     // 可选：从实体提取 name
}

// NewCRUDHandler 创建泛型 CRUD handler。
func NewCRUDHandler[T any](store CRUDStore[T], validateFn func(*T) string, setIDFn func(*T, string)) *CRUDHandler[T] {
	return &CRUDHandler[T]{store: store, validateFn: validateFn, setIDFn: setIDFn}
}

// WithNameCheck 添加 name 唯一性校验。
// checker 接收 name 返回 "" 表示允许或错误消息；getName 从实体提取 name。
func (h *CRUDHandler[T]) WithNameCheck(checker func(string) string, getName func(*T) string) *CRUDHandler[T] {
	h.nameChecker = checker
	h.getNameFn = getName
	return h
}

func (h *CRUDHandler[T]) List(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, h.store.List())
}

func (h *CRUDHandler[T]) Create(w http.ResponseWriter, r *http.Request) {
	var entity T
	if err := json.NewDecoder(r.Body).Decode(&entity); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	if msg := h.validateFn(&entity); msg != "" {
		http.Error(w, `{"error":"`+msg+`"}`, http.StatusBadRequest)
		return
	}
	if h.nameChecker != nil && h.getNameFn != nil {
		if msg := h.nameChecker(h.getNameFn(&entity)); msg != "" {
			http.Error(w, `{"error":"`+msg+`"}`, http.StatusConflict)
			return
		}
	}
	writeJSON(w, http.StatusCreated, h.store.Create(&entity))
}

func (h *CRUDHandler[T]) Get(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	entity, ok := h.store.Get(id)
	if !ok {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, entity)
}

func (h *CRUDHandler[T]) Update(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var entity T
	if err := json.NewDecoder(r.Body).Decode(&entity); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}
	h.setIDFn(&entity, id)
	updated, ok := h.store.Update(&entity)
	if !ok {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *CRUDHandler[T]) Delete(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !h.store.Delete(id) {
		http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
