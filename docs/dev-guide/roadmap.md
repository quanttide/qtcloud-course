# ROADMAP

> 产品级版本规划，侧重测试与文档。各 scope 详细路线图见 `src/*/ROADMAP.md`。

## 背景

LMS 能力（考核、班级 / 学员、认证、学生端播放器）已全部迁移至 [qtcloud-learn](../qtcloud-learn/ROADMAP.md)
（量潮学习云），本仓库回归**课程制作**单一职责。

**现状基线：**

- Studio：Scene 编辑器 / 分支选项 / 本地持久化 / JSON 导入导出 已完成
- Provider：课程内容 API（program / course / phase / lesson / scene）已就绪，SQLite 与视频上传待实施
- CLI：课程数据管线（`course` / `validate` / `import` / `export`）已发布 v0.1.0

## [v0.1] — 课程制作完善（进行中）

> **目标**：Studio 作为独立本地软件完成课程制作，编辑内容持久化不丢失。

### 交付物

- [x] Scene 编辑器 —— 创建/编辑/删除/排序场景和步骤
- [x] 分支选项 UI —— 步骤内分支选择、跳转目标场景配置
- [x] 本地模式默认 —— 不依赖 Provider API，默认读取本地 JSON
- [x] 本地持久化 —— 编辑内容自动保存到 `~/.qtcloud-course/data/`
- [x] JSON 导出/导入 —— 文件选择器导入导出课程结构

### 测试

- [x] Studio：`dart analyze` 零报错
- [x] Studio：`flutter test` 全部通过
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`

### 文档

- [ ] README 更新：本地模式说明、开发指南

## [v0.2] — 课程生产链路（规划中）

> **目标**：课程内容可发布、可同步、可供给学习云。

### 交付物

- [ ] 课程上架流程（草稿 → 审核 → 发布）
- [ ] 互动视频上传与管理（Provider 视频上传 API）
- [ ] CLI `publish` / `sync` 子命令
- [ ] 课程数据对接 `qtcloud-learn`（内容供给学习云）

### 测试

- [ ] CLI publish / sync 测试
- [ ] 集成测试：制作 → 上架 → 供给学习云

### 文档

- [ ] 上架流程文档
- [ ] 部署文档（视频存储）

## 质量门禁

- [ ] `go test ./... -count=1` 保持 90%+ 覆盖率
- [ ] `flutter test` + `dart analyze` CI 门禁
- [ ] 各版本发布前 CLI 验证流程可脚本化跑通
