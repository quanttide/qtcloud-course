# ROADMAP — Provider

> Provider 的内部版本与产品版本对齐关系：

| 产品版 | Provider 版 | 目标 |
|--------|-------------|------|
| v0.1 课程制作 | v0.0.3 → v0.1 | 嵌套路由 + SQLite 持久化 |
| v0.2 考核 | v0.2 | 考核 API + CI |
| v0.3 班级和学员 | v0.3 | 认证 + 权限 + 学习进度 |

## Architecture

```
v0.0.x          v0.1                v0.3
内存存储  ──→    SQLite         ──→  Postgres（可选）
无认证    ──→    无认证/DevToken ──→  飞书 OAuth
纯 CRUD   ──→    业务逻辑层      ──→  工作流引擎
```

## [v0.0.2] — 已发布

REST API 覆盖 Program / Course / Phase / Lesson / Scene / Class 六类资源的 CRUD。
纯 Go 标准库，无外部依赖。内存存储。

## [v0.0.3] — 进行中

> API 重构与数据加载。对齐产品级 **v0.1 课程制作**。

### 1. 路由重组：资源嵌套

将独立资源路径改为按父级嵌套，与数据模型的层级关系对齐。

#### Scenes 嵌套到 Lessons

```
# 当前                              # 改为
GET    /scenes?lessonId={id}        GET    /lessons/{id}/scenes
POST   /scenes                      POST   /lessons/{id}/scenes
GET    /scenes/{id}                 GET    /lessons/{id}/scenes/{sceneId}
PUT    /scenes/{id}                 PUT    /lessons/{id}/scenes/{sceneId}
DELETE /scenes/{id}                 DELETE /lessons/{id}/scenes/{sceneId}
```

- [ ] Scene handler 改为从 URL path 读取 lessonId，不再依赖查询参数
- [ ] POST 自动从路径推断 lessonId，请求体不再需要传 `lessonId`

#### Phases 嵌套到 Courses

```
# 当前                              # 改为
GET    /phases?courseId={id}        GET    /courses/{id}/phases
POST   /phases                      POST   /courses/{id}/phases
GET    /phases/{id}                 GET    /courses/{id}/phases/{phaseId}
PUT    /phases/{id}                 PUT    /courses/{id}/phases/{phaseId}
DELETE /phases/{id}                 DELETE /courses/{id}/phases/{phaseId}
```

- [ ] Phase handler 改为从 URL path 读取 courseId
- [ ] 嵌套后所有 Scene/Phase 操作都带有父级上下文

### 2. 数据加载

- [ ] `data/profile/` 中的 lesson JSON 支持带 Steps 的完整场景数据导入
- [ ] 环境变量 `DATA_DIR` 支持启动时加载 JSON 种子数据，替代 fixture 硬编码
- [ ] 提供 `make seed` 一键种子脚本
- [ ] 种子数据与 Studio assets JSON 同源，确保数据结构一致

### 3. 统一 name/title 字段

| 资源 | 当前有 | 需补齐 |
|------|--------|--------|
| Program | `name` | `title`（显示名副本） |
| Course | `name` | `title`（显示名副本） |
| Phase | `name` | `title`（显示名副本） |
| Lesson | `title` | `name`（URL slug） |
| Scene | `title` | `name`（URL slug） |
| Class | `name` | `title`（显示名副本） |

- [ ] Lesson/Scene 增加 `name` 字段（URL 友好的 slug）
- [ ] Program/Course/Phase/Class 增加 `title` 字段（显示名，初始化时与 `name` 相同）
- [ ] 所有资源的 `name` 在 Create 时自动从 `title` 生成 slug，也可手动指定
- [ ] Store 增加 `GetByName(name)` 方法
- [ ] Handler 增加 `GET /{resource}/name/{name}` 端点

### 4. 自动化测试补充

- [ ] name 重复校验测试
- [ ] 嵌套路由 handler 测试
- [ ] `go test ./... -count=1` 保持 90%+ 覆盖率

### 5. TechDebt：泛型化 CRUD 重构

6 个 Store（program/course/phase/lesson/scene/class）和 6 个 Handler 结构完全一致，
每个 Store 都是 `NewXStore → nextID → List → Get → Create → Update → Delete`，
仅类型名不同。Go 1.18+ 泛型可压缩为一份通用实现。

- [ ] 提取 `Store[T]` 泛型：`sync.RWMutex` + `map[string]*T` + 自增 ID
- [ ] 提取 `Handler[T, S]` 泛型：标准 CRUD HTTP handler + 校验函数注入
- [ ] 迁移后删除 5 个冗余 Store 文件和 5 个冗余 Handler 文件

## [v0.1] — 规划中

> SQLite 持久化存储。对齐产品级 **v0.1 课程制作**。

### Added
- [ ] SQLite 持久化存储（内置，不依赖外部数据库）
- [ ] 视频上传 API
- [ ] Provider 接口测试套件（Python pytest → HTTP）

## [v0.2] — 规划中

> 考核 API。对齐产品级 **v0.2 考核**。

### Added
- [ ] 考核 CRUD API
- [ ] 提交/评分 API
- [ ] 成绩统计 API

## [v0.3] — 规划中

> 用户与权限。对齐产品级 **v0.3 班级和学员**。

### Added
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员 / 讲师 / 学生）
- [ ] 班级管理 API：报名、进度跟踪
- [ ] 课程发布流程（草稿 → 审核 → 发布）
- [ ] 学习进度追踪
