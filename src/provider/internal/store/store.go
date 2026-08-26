// Package store 提供课程数据的存储层：内存（memory）、对象存储（OSS）与本地文件（local）。
//
// 持久化语义：每表一个对象（如 programs.json），保存该表的全量实体列表；
// 读时整体拉取、写时全量覆盖（原子写）——数据量小（教程级），简单可靠。
// 生产（FC 容器）用 OSS：容器可读写对象存储、容器回收数据仍在（解决 FC 无持久化问题）。
package store

import (
	"context"
	"errors"
)

// ErrNotFound 表示 key 对应的对象不存在。
var ErrNotFound = errors.New("store: key not found")

// Store 是对象存储抽象：以 key（逻辑对象名）读写 JSON 对象。
//
// 实现：
//   - oss：阿里云 OSS（生产，FC 可读写、容器回收数据仍在）
//   - local：本地文件系统（本地开发/验证，key 即文件路径）
//
// 对齐 qtcloud-crowd provider 的 Store 接口。
type Store interface {
	// Get 读取 key 对应的对象；不存在时返回 ErrNotFound。
	Get(ctx context.Context, key string) ([]byte, error)
	// Put 写入 key 对应的对象（覆盖语义）。
	Put(ctx context.Context, key string, data []byte) error
}
