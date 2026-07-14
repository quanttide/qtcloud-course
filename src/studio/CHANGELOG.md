# Changelog

## [0.0.5] - 2026-07-14

### Added
- 发布/下架功能：Program、Course、Lesson 可独立发布或下架
- Course 发布时检查子级 Lesson 状态，有草稿课时则提示确认
- 草稿课时在试听页顶部显示不可见提示横幅
- 空场景课时在试听页显示引导说明

### Changed
- 重构 ProgramService 从 CourseDataService 分离，main.dart 使用 MultiProvider 管理双 Service
- _ProgramScreen 重构：CRUD 类型分发从字符串改为 _NodeType 枚举
- DashboardScreen 通过双 Service 独立读取课程和班级数据
- PreviewScreen 导入 enums.dart 以支持 ContentStatus 判断

### Fixed
- 修复 loadLesson 回退逻辑：外部数据源失败后正确降级到树内版本
- 课程树新建课时后试听页展示友好的空场景提示

---

## [0.0.4] - 2026-07-14

### Added
- 新增底部导航到侧边栏的布局迁移，实现导航结构重构。
- 新增工作流文档（workflow.md），以用户路径为骨架嵌入功能定义，并补充场景式操作步骤及 P0/P1/P2 功能需求定义。
- 新增 ROADMAP 和 TODO 分离，更新 v0.0.4 规划并清理已完成任务。

### Changed
- 重构 Sidebar 版本显示为常量引用，统一版本号动态读取机制。
- 重构 UI 组件：将卡片组件和状态标签统一至 widgets/ 目录，拆分 PreviewScreen 为子组件，改进 DataService 错误处理。
- 文档重组：精简 ROADMAP 为战略级文档，清理旧版内容；更新 TODO.md 为 v0.0.4 任务。
- 集成测试与文档：GUI 测试和联调验证移至根级 TODO 统一管理。

### Fixed
- 修复版本号更新至 0.0.4，并修正 Sidebar 版本显示方式为常量引用。

### Removed
- 移除 ROADMAP.md（已由产品级 ROADMAP 覆盖）。
## [0.0.3] - 2026-07-14

### Added
- 新增双数据源、Scene videoUrl 字段及 API 模式测试
- 实现 PreviewScreen 试听预览页
- 新增 Scene 模型 Title、Steps、VerifyTip 字段
- 添加 studio GUI 自动化测试套件及视频播放测试页面

### Changed
- 重构 GUI 测试工具，迁移至 tests/utils/gui.py 并消除视频 URL 硬编码
- 更新 TODO 文档，标记 v0.0.3 已完成项并补充 API 契约、错误状态、videoUrl 字段
- 同步 provider 和 studio ROADMAP 与产品级 ROADMAP 对齐
- 将课堂视频测试页面移至 examples/，注册 studio scope 到 contract

### Fixed
- （无显著修复项）

### Removed
- 移除 Playwright 依赖及浏览器测试
- 移除 CHANGELOG 中 AI 自动添加的 0.1.0 条目
## [0.0.2] - 2026-07-13

### 新增

- 数据模型新增 Phase、Scene、Step、Choice，Course.lessons → Course.phases，Lesson 新增 sortOrder 和 scenes
- DataService 新增 `loadLesson(String lessonId)` 按需加载课时详情
- 课程研发页 Program → Course → Phase → Lesson → Scene → Step 六级展开树
- Lesson 行末增加"试听"按钮跳转预览页
- 新建 PreviewScreen 作为试听占位页
- 集成测试覆盖应用启动和试听跳转
- 开发文档 doc/ 记录架构、数据模型和测试策略

### 测试

- 添加 Phase、Scene、Step、Choice 模型单元测试
- 更新 Program/Course/Lesson 测试适配 phases 结构
- 添加 DataService 统计逻辑单元测试
- 更新 ProgramScreen Widget 测试适配多级展开

## [0.0.1] - 2026-05-08

### 新增

- 初始化 Flutter 项目 `qtcloud_course_studio`，支持 Android/iOS/Web/macOS/Linux 平台
- 添加 `provider` 状态管理和 JSON 数据加载服务
- 实现仪表盘页面：六张指标卡片（专业数、课程数、课时数、进行中班级、学员数、待处理）和两栏快捷列表
- 实现课程研发页面：Program→Course→Lesson 三级可展开树形结构，支持状态标记
- 实现教学管理页面：班级卡片列表，点击底部面板展示班级详情
- 设计 Program、Course、Lesson、ClassTeaching 四类数据模型，含 `fromJson` 工厂和 `copyWith` 方法
- 配置各平台应用显示名称为"量潮课程云"
- Linux 平台构建验证通过（`dart analyze` 零报错，`flutter build linux` 成功）

### 修复

- ClassScreen 尾部 Column 溢出

### 重构

- JSON 测试数据抽取到 `assets/fixtures/`，通过符号链接供 studio 引用

### 测试

- 添加 Program、Course、Lesson 模型单元测试
- 添加 ClassTeaching 模型单元测试
- 添加 ContentStatus、ClassStatus 枚举测试
- 添加 DashboardScreen、ProgramScreen、ClassScreen Widget 测试
- 添加应用启动 Widget 测试
