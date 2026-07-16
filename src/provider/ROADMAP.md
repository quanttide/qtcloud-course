# ROADMAP — Provider

## [0.0.2] — 已发布

REST API 覆盖 Program / Course / Phase / Lesson / Scene / Class 六类资源的 CRUD。纯 Go 标准库，无外部依赖。内存存储。

### Architecture

```
v0.0.x          v0.1.x              v0.2.x
内存存储  ──→    SQLite         ──→  Postgres（可选）
无认证    ──→    无认证/DevToken ──→  飞书 OAuth
纯 CRUD   ──→    业务逻辑层      ──→  工作流引擎
```

## [0.0.3] — 进行中

> API 重构与数据加载。对应产品级 `v0.1.0` 里程碑。

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

## [0.1.0] — 规划中

> 持久化与业务增强。对应产品级 `v0.2.0` 里程碑。

### Added
- [ ] SQLite 持久化存储（内置，不依赖外部数据库）
- [ ] 班级管理 API：报名、进度跟踪
- [ ] 视频上传 API
- [ ] Provider 接口测试套件（Python pytest → HTTP）

## [0.2.0] — 远期

> 用户与权限。对应产品级 `v0.3.0` 里程碑。

### Added
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员 / 讲师 / 学生）
- [ ] 课程发布流程（草稿 → 审核 → 发布）
- [ ] 学习进度追踪
