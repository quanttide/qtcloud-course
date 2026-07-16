# ROADMAP

> 产品级版本规划。各 scope 版本详见 `src/*/ROADMAP.md`。

## [0.2.0] — 规划中

> **课程内容制作**：从蓝图到互动课时的端到端链路打通。

### Added
- [ ] **Scene 编辑器**：在 Studio GUI 中创建/编辑场景、步骤、分支选项，不再依赖手写 JSON
- [ ] **数据管线**：CLI `blueprint` 输出结构化 JSON，Studio 可直接导入
- [ ] **持久化存储**：Provider SQLite 替代内存存储，关闭不丢数据
- [ ] **场景内容导入**：支持 JSON 文件批量导入课时内容

## [0.1.0] — 进行中

> **课程结构编辑**：能完成课程结构设计与预览。当前进度 34%

### Added
- [x] CLI blueprint 子命令：AI 生成课程蓝图
- [x] Studio 四级 CRUD：Program → Course → Phase → Lesson
- [x] Studio 互动课堂预览：场景导航 + 步骤面板 + 分支选项 + 完成页
- [x] Provider REST API：六类资源 CRUD
- [x] JSON 导入/导出：离线备份与迁移
- [x] Studio 班级管理：创建班级、统计学生数、进度条
- [x] 集成测试套件：pytest 端到端测试 + JSON schema 校验
- [x] DevOps 契约：contract.yaml + ROADMAP 可追踪
- [ ] CI 工作流：三 scope 自动构建+测试
- [ ] 版本号对齐：三种语言统一发布节奏
- [ ] Studio 考核管理：导航独立 + 提交工作流 + 批量评分（v0.0.7）
- [ ] Provider 嵌套路由 + name/title 统一（v0.0.3）

### Fixed
- [x] Studio `dart analyze` 红线：assets 缩进错误
- [x] DevOps 契约缺失：`.quanttide/devops/contract.yaml` 已创建

### TechDebt
- [ ] CLI 零测试：`blueprint.rs` + `main.rs` 无对应 `*_test.rs`
- [ ] Provider 样板代码：6 Store + 6 Handler 结构完全一致，可用泛型消除 ~70% 重复
- [ ] Studio Service 重复：三份 `_apiPost/Put/Delete` 待抽取 mixin
- [ ] GUI 测试不可移植：16 个 pytest 测试依赖真实 Flutter 进程，CI 无法运行

## [0.3.0] — 远期

> **教学交付**：学生能登录、选课、学习、考试。

### Added
- [ ] 学生端播放器（Web/移动端）
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员/讲师/学生）
- [ ] 课程上架流程（草稿 → 审核 → 发布）
- [ ] 学习进度追踪
- [ ] 互动视频上传与管理
