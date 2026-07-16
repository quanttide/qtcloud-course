# ROADMAP

## [0.1.0] — 进行中

> 三个组件（Studio/Provider/CLI）构建绿色、测试覆盖、CI 就绪

### Added
- [x] Studio 构建修复：assets 路径缩进错误
- [ ] CLI 测试文件补充（`blueprint.rs`、`main.rs` 对应 `*_test.rs`）
- [ ] Studio CI：push 自动跑 `flutter test` + `dart analyze`
- [ ] Provider CI：push 自动跑 `go test ./...`
- [ ] CLI CI：push 自动跑 `cargo test`
- [ ] Provider v0.0.3：嵌套路由 + 数据加载 + name/title 统一
- [ ] Studio v0.0.7：考核管理独立导航 + 学生提交工作流 + 批量评分
- [ ] Contract 配置：`.quanttide/devops/contract.yaml`

### Fixed
- [x] Studio: `pubspec.yaml` assets 缩进导致 `dart analyze` 失败
- [ ] Studio: 三 Service 重复的 `_apiPost/Put/Delete` 提取为 mixin

## [0.0.2] — 已发布

### Added
- [x] Provider REST API：Program/Course/Phase/Lesson/Scene/Class 六类 CRUD
- [x] Studio Flutter 客户端：四级 CRUD（Program/Course/Phase/Lesson）
- [x] CLI bluepring 子命令：AI 生成课程蓝图
- [x] JSON 双轨互通：导入/导出
- [x] 集成测试套件（pytest）
- [x] 测试数据 fixture（JSON schema 校验）

## [0.1.0] — 规划中

### Added
- [ ] Provider SQLite 持久化
- [ ] Provider 视频上传 API
- [ ] Studio iOS/Android 多平台构建
- [ ] 统一发布流程（`qtcloud-devops release publish` 一键发布）
- [ ] 版本号对齐：三组件统一版本节奏

## [0.2.0] — 远期

### Added
- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员/讲师/学生）
- [ ] 课程发布审核流程
- [ ] 学习进度追踪
