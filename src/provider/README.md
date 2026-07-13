# qtcloud-course-provider

量潮课程云服务端。提供课程研发与教学管理的 RESTful API。

## 技术栈

- Go 1.22+
- 纯标准库 `net/http`（增强 ServeMux），无外部依赖
- 当前使用内存存储，重启后数据丢失


## 生产构建

```bash
go build -o bin/server ./cmd/server
```

---

## 快速开始

```bash
go run ./cmd/server
```

服务默认监听 `:8080`，可通过 `LISTEN_ADDR` 环境变量覆盖：

```bash
LISTEN_ADDR=:9090 go run ./cmd/server
```


## 测试

```bash
go test ./... -count=1 -cover
```
