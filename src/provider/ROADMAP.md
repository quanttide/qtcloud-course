# ROADMAP — Provider

> Provider 定位：课程内容服务端。LMS 能力（考核、班级 / 学员、认证）已迁移至 `qtcloud-learn`，本 scope 聚焦课程内容 API。

| Provider 版 | Studio 版 | 目标 |
|-------------|-----------|------|
| v0.0 (已发布) | v0.0.5/v0.0.6 | 课程结构资源 CRUD |
| v0.1 (进行中) | v0.1 | 课程制作：嵌套路由 + OSS 持久化 + 数据加载 + 验收标准模型 |

## Architecture

```
v0.0             v0.1                v0.2
内存存储  ──→    OSS 持久化    ──→  视频存储 + 发布
无认证    ──→    无认证/DevToken ──→  DevToken
纯 CRUD   ──→    业务逻辑层      ──→  上架流程
```

## [v0.0] — 已发布

REST API 覆盖 Program / Course / Phase / Lesson / Scene 课程结构资源的 CRUD。
纯 Go 标准库，无外部依赖。内存存储。

## [v0.1] — 课程制作（进行中）

> API 重构 + 嵌套路由 + 数据加载 + OSS 持久化。对齐 Studio **v0.1 课程制作**。
> 持久化：对象存储（OSS）替代 SQLite——FC 容器无持久盘，每表一个对象（{table}.json），
> 懒加载 + 写时全量覆盖原子写（解决 FC 无持久化问题，见 docs/dev-guide/upgrade.md）。

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

### Phase 4：OSS 持久化 ✅
- [x] **OSS 持久化**：每表一个对象（programs.json / courses.json / phases.json / lessons.json / scenes.json），懒加载（首次读时拉取、内存缓存）+ 写时全量覆盖原子写
- [x] **OSSStore[T]**：与 SQLiteStore 同接口（List/Get/Create/Update/Delete/NameExists/ListWhere/SetID），对齐 qtcloud-crowd 的 OSS store 模式（aliyun SDK + QTCLOUD_OSS_* 配置）
- [x] **配置**：`QTCLOUD_COURSE_STORE=oss|memory`（默认 memory 测试）；seed/seed-catalog 同步迁移（写入 OSS，Dockerfile 启动时先 seed）
- [x] **OSS store 单测**：mock OSS server（对齐 qtcloud-crowd oss_test）覆盖 CRUD/持久化/ListWhere/SetID/快照格式

### Phase 5：视频上传
- [ ] **视频上传 API**：POST /upload/video，multipart 接收

### Phase 6：验收标准模型 ✅
- [x] **内嵌验收**：Lesson/Scene 加 `Acceptance{criteria, method, on_fail}`——课时总验收 + 场景级每步判定两层同构（v0.1.1-alpha.2）
- [x] **Criterion 一等实体**：验收标准升格为独立资源（id/title/description，单一事实源在本领域），`/lessons/{lessonId}/criteria` CRUD 与列表路由（含 `GET /criteria` 全局清单）
- [x] **Acceptance 引用式**：criteria 由文字字段改为标准 ID 引用列表（method/on_fail 执行配置保留在挂载处）

> 模型对齐目标：qtclass `docs/dev-guide/provider.md`（同源直连 + 注册时快照协议）。

### Phase 7：API 路径统一 ✅
- [x] **取消公开 API 的 `/v1` 前缀**：接口路径统一为资源根路径（原 `GET /v1/courses` → `GET /courses`）；同步调整 Studio 客户端基址与两侧文档（qtclass `docs/dev-guide/provider.md`、qtclass `src/provider/ROADMAP.md`）

### 模型裁剪（2026-08-28 决策）✅

服务端只出内容实体，前端视图适配职责移交应用侧（qtclass provider）：

- [x] **删除 Program 与 Phase**：课程树简化为三级 Course → Lesson → Scene，Lesson 归属课程（新增 courseId/sortOrder），目录阶梯顺序由 Course.sortOrder 承担；seed 脚本同步重写
- [x] **删除播放器适配 API**：移除 `/player-data`、`/courses/{id}/player` 及 icon/badge 等展示字段——播放器数据组装归 qtclass provider
- [x] **取消 `/video` 静态文件服务与 VIDEO_DIR 配置**：视频地址由 Scene.videoUrl 直接指向对象存储
- [x] **Acceptance 结构裁剪**：Lesson/Scene 直接持有 `criteria []string` 标准 ID 引用列表，method/on_fail 执行配置字段移除
- [x] **验收标准增加场景级挂载**：Criterion 新增可选 sceneId，`GET|POST /scenes/{sceneId}/criteria` 子路由（创建自动回填所属课时）
- 接口清单见 `docs/api-references/provider.md`

### 质量门禁
- [ ] `go test ./... -count=1` 保持 90%+ 覆盖率
- [ ] 所有 Phase 完成后发布 v0.1.0 tag

## [v0.2] — 课程生产（规划中）

> 课程上架与素材管理，对齐根 ROADMAP v0.2。

### Added
- [ ] 课程上架 API（草稿 → 审核 → 发布状态流转）
- [ ] 课程数据供给 `qtcloud-learn`（学习云内容源）：Criterion 清单经 seed 管道向学习云注册快照（id/title 同源直连、description 冻结归档），完成记录回写由学员端直连学习云，本领域不感知
