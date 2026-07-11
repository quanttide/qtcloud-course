# Changelog

## [0.1.0] - 2026-07-11

### Provider 服务端

- 初始化 Go 语言服务端项目 `src/provider/`，零外部依赖，使用 Go 1.22+ 标准库 `net/http` 增强 ServeMux 路由
- 实现 Program→Course→Lesson 三级嵌套数据的完整 CRUD API（`/programs/...`, `/classes/...`）
- 实现 Class 教学单位的完整 CRUD API
- 添加线程安全的内存存储层，可替换为持久化方案
- 服务端口默认 `:8080`，支持 `LISTEN_ADDR` 环境变量

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
