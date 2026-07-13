# Changelog

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
