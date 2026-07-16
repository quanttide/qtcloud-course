# ROADMAP

> 产品级版本规划，侧重测试与文档。各 scope 详细路线图见 `src/*/ROADMAP.md`。

## [v0.1] — 课程制作（进行中）

> **目标**：Studio 作为独立本地软件完成课程制作，编辑内容持久化不丢失。

### 测试
- [x] Studio：`dart analyze` 零报错
- [ ] Studio：`flutter test` 全部通过
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`

### 文档
- [ ] README 更新：本地模式说明、开发指南

### 交付物
- [x] Scene 编辑器 —— 创建/编辑/删除/排序场景和步骤
- [x] 分支选项 UI —— 步骤内分支选择、跳转目标场景配置
- [x] 本地模式默认 —— 不依赖 Provider API，默认读取本地 JSON
- [x] 本地持久化 —— 编辑内容自动保存到 `~/.qtcloud-course/data/`
- [x] JSON 导出/导入 —— 文件选择器导入导出课程结构
- [ ] `flutter test` 全部通过

---

> 以下 Provider/CLI 条目延至后续版本，Studio v0.1.0 聚焦独立本地模式。

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
