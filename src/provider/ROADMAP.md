# ROADMAP — Provider

> Provider 版本与 Studio 一一对应，每个里程碑提供 API 层面等价能力。

| Provider 版 | Studio 版 | 目标 |
|-------------|-----------|------|
| v0.0 (已发布) | v0.0.5/v0.0.6 | 六类资源 CRUD |
| v0.1 (进行中) | v0.1 | 课程制作：嵌套路由 + SQLite + 数据加载 |
| v0.2 | v0.2 | 考核：考核/提交/评分/统计 API |
| v0.3 | v0.3 | 班级和学员：认证 + 权限 + 进度追踪 |

## Architecture

```
v0.0             v0.1                v0.3
内存存储  ──→    SQLite         ──→  Postgres（可选）
无认证    ──→    无认证/DevToken ──→  飞书 OAuth
纯 CRUD   ──→    业务逻辑层      ──→  工作流引擎
```

## [v0.0] — 已发布

REST API 覆盖 Program / Course / Phase / Lesson / Scene / Class 六类资源的 CRUD。
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
- [x] **泛型 CRUDHandler**：`CRUDHandler[T]` 消除 Program/Course/Lesson/Class 四个 Handler 的 CRUD 模板代码
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

---

## [v0.2] — 考核（规划中）

> 考核 API。对齐 Studio **v0.2 考核**。

### Added
- [ ] 考核 CRUD API
- [ ] 提交 API：学生提交作答
- [ ] 评分 API：批量评分 + 评语
- [ ] 成绩统计 API：平均分 / 及格率 / 分布
- [ ] 考试模式 API：题型（选择/填空/简答）+ 自动评分 + 计时

## [v0.3] — 班级和学员（规划中）

> 认证 + 权限 + 班级管理。对齐 Studio **v0.3 班级和学员**。

### Added
- [ ] 班级管理 API：创建/编辑/删除/列表
- [ ] 学员管理 API：邀请/加入/退班/名单
- [ ] 学习进度追踪 API
- [ ] 班级仪表盘 API：统计卡片 / 进度分布
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员 / 讲师 / 学生）
- [ ] 课程发布流程（草稿 → 审核 → 发布）
- [ ] Postgres 支持（可选）
