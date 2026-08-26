# CHANGELOG


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
