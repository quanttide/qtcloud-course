# ROADMAP

> 产品级版本规划，侧重测试与文档。各 scope 详细路线图见 `src/*/ROADMAP.md`。

## [v0.1] — 课程制作（进行中）

> **目标**：打通从蓝图到互动课时的端到端链路，三 scope 测试就绪。

### 测试
- [ ] Studio：`flutter test` 全部通过 + `dart analyze` 零报错
- [ ] Studio：GUI 测试 16 个修复并行化 + CI 跳过标记
- [ ] Provider：`go test ./... -count=1` 保持 90%+ 覆盖率
- [ ] Provider：name 重复校验 + 嵌套路由 handler 测试
- [ ] CLI：`blueprint.rs` + `main.rs` 对应 `*_test.rs` 测试覆盖
- [ ] CLI：mock 注入解耦，`blueprint::run` 可单元测试
- [ ] 集成测试：全链路场景（CLI 输出 → Studio 导入 → Provider 持久化）
- [ ] CI 工作流：三 scope 自动构建 + 测试 + 覆盖率门禁

### 文档
- [ ] Studio：README 更新安装与开发指南
- [ ] Provider：API 文档（路由表 / 请求响应示例）
- [ ] CLI：子命令帮助文档 + README 使用示例
- [ ] 集成测试：测试数据 fixture 文档 + JSON schema 说明

### 交付物
- [x] Scene 编辑器 —— 创建/编辑场景、步骤，与 Provider API 打通
- [x] API 模式默认 —— Studio 默认走 Provider API，本地 JSON 降级为回退
- [ ] 数据管线 —— CLI `blueprint --format json` → Studio 一键导入
- [ ] Provider 嵌套路由 —— Scenes/Phases 按父级嵌套 + name/title 统一
- [ ] CLI 结构化输出 —— `blueprint --format json` + validate/import/export
- [ ] 分支选项 UI + 导入预览 + schema 校验
- [ ] SQLite 持久化 + 场景内容 JSON 批量导入
- [ ] 多平台构建 iOS/Android

---

## [v0.2] — 考核（规划中）

> **目标**：考核全流程可操作，三 scope 测试覆盖 + 文档完备。

### 测试
- [ ] Studio：考核模块 `flutter test` 全覆盖
- [ ] Provider：考核 CRUD + 提交/评分 API 测试 90%+ 覆盖率
- [ ] CLI：assessment 子命令测试
- [ ] 集成测试：考核全流程（创建 → 提交 → 评分 → 统计）

### 文档
- [ ] Studio：考核模块使用指南
- [ ] Provider：考核 API 文档
- [ ] CLI：assessment 子命令帮助文档
- [ ] 用户手册：教师考核操作流程

### 交付物
- [ ] Studio 考核导航独立
- [ ] Studio 学生提交工作流 + 批量评分 + 成绩概览
- [ ] Studio 考试模式（题型 / 自动评分 / 计时）
- [ ] Provider 考核 / 提交 / 评分 / 统计 API
- [ ] CLI assessment 子命令（create / submit / grade / stats）

---

## [v0.3] — 班级和学员（规划中）

> **目标**：班级管理和学员体系完善，多角色认证就绪。

### 测试
- [ ] Studio：班级/学员模块 `flutter test` 全覆盖
- [ ] Provider：认证 + 权限测试
- [ ] CLI：class / student 子命令测试
- [ ] 集成测试：学员全流程（注册 → 加入班级 → 学习 → 进度查看）

### 文档
- [ ] Studio：班级管理使用指南
- [ ] Provider：认证 / 权限 API 文档
- [ ] CLI：class / student 子命令帮助文档
- [ ] 部署文档：认证配置（飞书登录）

### 交付物
- [ ] Studio 班级 CRUD + 学员管理 + 班级仪表盘 + 学习进度追踪
- [ ] 用户认证（飞书登录）+ 角色权限（管理员 / 讲师 / 学生）
- [ ] 课程上架流程（草稿 → 审核 → 发布）
- [ ] 学生端播放器（Web/移动端）
- [ ] 互动视频上传与管理
- [ ] CLI class / student 子命令 + sync / publish
- [ ] Postgres 支持（可选）
