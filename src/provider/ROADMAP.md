# ROADMAP — Provider

> Provider 定位：课程内容服务端。LMS 能力（考核、班级 / 学员、认证）已迁移至 `qtcloud-learn`，本 scope 聚焦课程内容 API。

| Provider 版 | Studio 版 | 目标 |
|-------------|-----------|------|
| v0.0 (已发布) | v0.0.5/v0.0.6 | 课程结构资源 CRUD |
| v0.1 (进行中) | v0.1 | 课程制作：嵌套路由 + SQLite + 数据加载 |

## Architecture

```
v0.0             v0.1                v0.2
内存存储  ──→    SQLite         ──→  视频存储 + 发布
无认证    ──→    无认证/DevToken ──→  DevToken
纯 CRUD   ──→    业务逻辑层      ──→  上架流程
```

## [v0.0] — 已发布

REST API 覆盖 Program / Course / Phase / Lesson / Scene 课程结构资源的 CRUD。
纯 Go 标准库，无外部依赖。内存存储。

## [v0.1] — 课程制作（进行中）

> API 重构 + 嵌套路由 + 数据加载 + SQLite 持久化。对齐 Studio **v0.1 课程制作**。

按依赖关系分阶段实施：

### Phase 1：路由重构与配置统一 ✅
- [x] **嵌套路由**：Scenes → `GET /lessons/{lessonId}/scenes`，Phases → `GET /courses/{courseId}/phases`
- [x] **统一 name/title**：所有资源暴露 slug 字段，Create 时自动生成
- [x] **环境配置统一**：`internal/config` 包集中管理 `LISTEN_ADDR`、`DATA_DIR`、`VIDEO_DIR`

### Phase 2：泛型化 CRUD ✅
- [x] **泛型 BaseStore**：`BaseStore[T]` 消除 List/Get/Delete 共 192 行重复代码
- [x] **泛型 CRUDHandler**：`CRUDHandler[T]` 消除 Program/Course/Lesson 三个 Handler 的 CRUD 模板代码
- [x] **name 重复校验**：`NameExists` 方法 + `WithNameCheck` 链式配置，Create 重复返回 409
- [x] 嵌套路由 handler 测试 + name 重复校验测试

### Phase 3：数据加载与种子脚本
- [ ] **数据加载**：`DATA_DIR` 环境变量 + `make seed` 一键种子脚本
- [ ] **接口测试套件**（Python pytest → HTTP）

### Phase 4：SQLite 持久化
- [ ] **SQLite 持久化**：内置 SQLite（modernc.org/sqlite），替代内存存储，关闭不丢数据

### Phase 5：视频上传
- [ ] **视频上传 API**：POST /upload/video，multipart 接收

### 质量门禁
- [ ] `go test ./... -count=1` 保持 90%+ 覆盖率
- [ ] 所有 Phase 完成后发布 v0.1.0 tag

## [v0.2] — 课程生产（规划中）

> 课程上架与素材管理，对齐根 ROADMAP v0.2。

### Added
- [ ] 课程上架 API（草稿 → 审核 → 发布状态流转）
- [ ] 课程数据供给 `qtcloud-learn`（学习云内容源）
