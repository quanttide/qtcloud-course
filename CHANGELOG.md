# Changelog

## [0.0.1] - 2026-05-08

### Studio 客户端初始化

- 初始化 Flutter 项目 `qtcloud_course_studio`，支持 Android/iOS/Web/macOS/Linux 平台
- 添加 `provider` 状态管理和 JSON 数据加载服务
- 实现仪表盘页面：六张指标卡片（专业数、课程数、课时数、进行中班级、学员数、待处理）和两栏快捷列表
- 实现课程研发页面：Program→Course→Lesson 三级可展开树形结构，支持状态标记
- 实现教学管理页面：班级卡片列表，点击底部面板展示班级详情
- 设计 Program、Course、Lesson、ClassTeaching 四类数据模型，含 `fromJson` 工厂和 `copyWith` 方法
- 添加模拟数据（3 个专业、4 个班级），使用 JSON 文件加载
- 配置各平台应用显示名称为"量潮课程云"
- Linux 平台构建验证通过（`dart analyze` 零报错，`flutter build linux` 成功）
- 添加自动录屏脚本 `scripts/record-studio-linux.sh`（ffmpeg + xdotool）
- 首次演示录制视频 `assets/videos/studio.mp4`
