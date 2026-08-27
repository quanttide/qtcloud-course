# CHANGELOG

## [0.1.1-alpha.5] - 2026-08-27

### Changed

- 领域模型改为复用 course-toolkit（packages/go v0.1.1-α3 alpha.3）：type alias 替代本地重复定义，单一事实源归位
- 路由注册改引 toolkit Route* 常量，消除手写路由字符串

## [0.1.1-alpha.4] - 2026-08-28

### Added

- 验收标准升格为一等实体：新增 Criterion{id, lessonId, title, description}（id/title 学习云同源直连，description 为课程侧事实源），`/lessons/{lessonId}/criteria` CRUD + `GET /criteria` 全局清单；OSS 持久化同步（criteria 表）

### Changed

- Acceptance 由文字字段改为标准 ID 引用列表（criteria []string）——对齐 qtclass `docs/dev-guide/provider.md` 快照协议
- **破坏性**：公开 API 取消 `/v1` 前缀，路径统一为资源根路径（`GET /courses` 等）；文档清单见 `docs/api-references/provider.md`
- **破坏性**：删除 Program 与 Phase 模型（课程树简化为三级 Course → Lesson → Scene，Lesson 归属课程并携带 sortOrder）、删除播放器适配 API（/player-data 与 icon/badge 等展示字段——组装职责移交 qtclass provider）、删除 `/video` 静态服务与 VIDEO_DIR；seed/seed-catalog 同步重写
- 验收标准支持场景级挂载：Criterion 新增可选 sceneId，`/scenes/{sceneId}/criteria` 子路由
- Acceptance 结构裁剪：删除嵌套验收对象与 method/on_fail 字段，Lesson/Scene 直接持 `criteria []string` 标准 ID 引用列表


## [0.1.1-alpha.3] - 2026-08-27

### Changed

- 无代码变更（与 0.1.1-alpha.2 同内容）：alpha.2 部署因 CI 并发排队中断，重发布触发 Deploy Provider 重新部署

## [0.1.1-alpha.2] - 2026-08-26

### Added

- 验收标准模型：Lesson/Scene 加 Acceptance{criteria, method, on_fail}（课时总验收 + 场景级每步判定——两层同构；Course 不加——课程完成 = 课时全过）

## [0.1.1-alpha.1] - 2026-08-26

### Changed

- 持久化从 SQLite 更换为 OSS 对象存储（每表单对象全量原子写 + 懒加载缓存——解决 FC 无持久化）
- 配置：QTCLOUD_COURSE_STORE=oss|memory（默认 memory）+ QTCLOUD_OSS_*（桶 qtcloud-course-provider）
- seed/seed-catalog 适配 OSS——Dockerfile 启动链 seed → seed-catalog → server

## [0.1.0] - 2026-08-01

### Removed
- 移除 LMS 班级能力（迁移至 `qtcloud-learn`，见其 ROADMAP v0.5）：`class.go`（domain / store / handler）、`/classes` 路由与相关测试

## [0.0.2] - 2026-07-13

### Added
- 新增 Phase 阶段模型及视频静态服务
- 新增 Scene/Choice 互动课时模型
- 初始化 Go 服务端架构
- 添加项目 README 文档

### Changed
- 将 Course 和 Lesson 重构为独立资源模块
- 提升代码测试覆盖率至 98.8%
- 注册 provider 发布范围并更新 CHANGELOG 历史条目
- 更新依赖锁与版本配置

### Removed
- 移除 CHANGELOG 中 AI 自动生成的 0.1.0 条目
## [0.0.1] - 2026-07-11

### Added
- 新增服务端初始化及 Scene/Choice 互动课时模型

### Changed
- 重构 Course/Lesson 为独立资源
- 优化测试覆盖率至 98.8%
- 注册 provider 发布范围

### Removed
- 移除 CHANGELOG 中自动添加的 0.1.0 条目
