# ROADMAP

> 产品级版本规划。各 scope 版本详见 `src/*/ROADMAP.md`。

## [v0.1] — 课程制作（进行中）

> 从蓝图到互动课时的端到端链路打通。补齐 Scene 编辑器，不再依赖手写 JSON，数据管线连通 CLI → Studio → Provider。

### Added
- [x] CLI blueprint 子命令：AI 生成课程蓝图
- [x] Studio 四级 CRUD：Program → Course → Phase → Lesson
- [x] Studio 互动课堂预览：场景导航 + 步骤面板 + 分支选项 + 完成页
- [x] Provider REST API：六类资源 CRUD
- [x] Studio 班级管理：创建班级、统计学生数、进度条
- [x] JSON 导入/导出：离线备份与迁移
- [x] 集成测试套件：pytest 端到端测试 + JSON schema 校验
- [x] DevOps 契约：contract.yaml + ROADMAP 可追踪
- [ ] **Scene 编辑器**：在 Studio GUI 中创建/编辑场景、步骤、分支选项
- [ ] **数据管线**：CLI `blueprint` 输出结构化 JSON，Studio 可直接导入
- [ ] **持久化存储**：Provider SQLite 替代内存存储，关闭不丢数据
- [ ] **场景内容导入**：支持 JSON 文件批量导入课时内容
- [ ] **路由重组**：Provider 嵌套路由 + name/title 统一
- [ ] CI 工作流：三 scope 自动构建+测试
- [ ] 版本号对齐：三种语言统一发布节奏
- [ ] CLI 结构化输出：`blueprint --format json` + validate/import/export 子命令

### TechDebt
- [ ] CLI 零测试：`blueprint.rs` + `main.rs` 无对应 `*_test.rs`
- [ ] Provider 样板代码：6 Store + 6 Handler 可用泛型消除 ~70% 重复
- [ ] Studio Service 重复：三份 `_apiPost/Put/Delete` 待抽取 mixin
- [ ] GUI 测试不可移植：16 个 pytest 测试依赖真实 Flutter 进程，CI 无法运行

## [v0.2] — 考核（规划中）

> 考核管理从教学管理分离，成为独立导航入口，覆盖完整考核流程。

### Added
- [ ] Studio 考核导航独立：侧边栏新增「考核管理」tab
- [ ] Studio 学生提交工作流：筛选/标记/提交内容
- [ ] Studio 批量评分面板：全班集中评分 + 连续评分模式
- [ ] Studio 成绩概览：统计卡片 / 分布图 / 导出
- [ ] Studio 考试模式：题型（选择/填空/简答）+ 自动评分 + 计时
- [ ] Provider 考核相关 API
- [ ] CLI `sync` 子命令：CLI ↔ Provider API 双向同步
- [ ] CLI `publish` 子命令：批量发布/下架课程结构
- [ ] CI 完善 + 技术债清扫（Studio Service mixin、lint 规则、GUI 测试并行化）

## [v0.3] — 班级和学员（规划中）

> 班级管理和学员体系完善，支持学员加入/退班、学习进度追踪。

### Added
- [ ] Studio 班级 CRUD 完善：创建/编辑/删除/列表
- [ ] Studio 学员管理：邀请加入/审核/退班/学员名单
- [ ] Studio 班级仪表盘：统计卡片 / 进度分布 / 导出
- [ ] Studio 学员学习进度追踪：个人学习记录 / 完成率 / 趋势
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员 / 讲师 / 学生）
- [ ] 课程上架流程（草稿 → 审核 → 发布）
- [ ] 学生端播放器（Web/移动端）
- [ ] 互动视频上传与管理
- [ ] Provider SQLite → Postgres（可选）
