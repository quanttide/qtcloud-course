# Changelog


## [0.0.2] - 2026-07-13

### Added
- 新增 studio GUI 自动化测试套件及 PreviewScreen 试听预览页，实现 Phase/Scene/Step 模型和六级编排树
- 新增 Scene 模型字段（Title/Steps/VerifyTip），完善领域模型
- 新增 Go 服务端 provider，包含 Phase 阶段模型、视频静态服务、Scene/Choice 互动课时模型
- 新增 pytest 测试框架，添加视频服务测试、视频可播放性验证及课堂视频播放自动化测试
- 新增 ROADMAP、TODO.md、CONTRIBUTING.md 等文档，明确开发路线与贡献规范

### Changed
- 重构测试文件：移动并抽离 GUI 测试工具到 tests/utils/gui.py，消除视频 URL 硬编码，测试改用 tmp_path_factory，重命名 test_server 为 test_provider
- 重构 provider：将 API 文档移至 docs/api/index.md，拆解 Course/Lesson 为独立资源
- 更新依赖锁文件 uv.lock 和 Cargo.lock
- 修订文档：审核 ROADMAP 和 TODO.md，补充 Phase 缺失，精简 v0.0.3 规划

### Fixed
- 修复版本号从 1.0.0 改为 0.0.1，对齐 CHANGELOG 和 git tag

### Removed
- 移除 Playwright 依赖及浏览器测试
- 移除冗余集成测试（由 PreviewScreen 替代）
- 移除 CHANGELOG 中由 AI 自动添加的 0.1.0 条目
## [0.0.1] - 2026-05-08

### 架构设计

- 添加课程云架构设计文档 `docs/add/index.md`，明确两个子领域划分：课程单位（Program→Course→Lesson）和教学单位（Class）
- 定义领域边界原则：课程单位定义内容，教学单位负责实施；课程域不引用组织域

### 交互设计

- 添加仪表盘页面 IXD `docs/ixd/dashboard.md`：双角色指标卡片、待办事项、快捷操作
- 添加课程研发页面 IXD `docs/ixd/course.md`：三级树形导航、内容编辑、AI 生成内容交互
- 添加教学管理页面 IXD `docs/ixd/teaching.md`：班级列表+详情面板、教学日历、开结课流程

### 数据规范

- 添加 DRD 数据需求文档 `docs/drd/`：README + program.md + class_teaching.md
- 定义 Program→Course→Lesson 三级数据 schema 和 ContentStatus 枚举
- 定义 ClassTeaching 数据 schema，含 ClassStatus/RefType 枚举
- 提取 JSON 模拟数据到 `assets/fixtures/`，通过符号链接供 studio 引用

### Studio 客户端

- 初始化 Flutter 项目 `qtcloud_course_studio`，支持 Android/iOS/Web/macOS/Linux 平台
- 添加 `provider` 状态管理和 JSON 数据加载服务
- 实现仪表盘页面：六张指标卡片（专业数、课程数、课时数、进行中班级、学员数、待处理）和两栏快捷列表
- 实现课程研发页面：Program→Course→Lesson 三级可展开树形结构，支持状态标记
- 实现教学管理页面：班级卡片列表，点击底部面板展示班级详情
- 设计 Program、Course、Lesson、ClassTeaching 四类数据模型，含 `fromJson` 工厂和 `copyWith` 方法
- 配置各平台应用显示名称为"量潮课程云"
- Linux 平台构建验证通过（`dart analyze` 零报错，`flutter build linux` 成功）

### 工具链

- 添加自动录屏脚本 `scripts/record-studio-linux.sh`（ffmpeg + xdotool）
- 首次演示录制视频 `assets/videos/studio.mp4`
