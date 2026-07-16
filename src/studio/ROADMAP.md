# ROADMAP — Studio

## [v0.1] — 课程制作（进行中）

> 补齐 Scene 编辑器，不再依赖手写 JSON，打通从蓝图到互动课时的端到端链路。

### Added
- [x] Scene 编辑器：创建/编辑场景、步骤，与 Provider API 打通
- [ ] 数据管线：一键导入 CLI blueprint 结构化 JSON 为课程结构
- [x] API 模式默认：不再依赖本地 JSON 启动（本地 JSON 降级为离线回退）
- [ ] 环境配置统一（`api_base_url`、`data_dir`）
- [ ] 分支选项 UI：步骤内分支选择、跳转逻辑配置
- [ ] 导入预览：确认/回滚导入结果
- [ ] JSON schema 校验 + 错误提示
- [ ] iOS 构建验证（`flutter build ios`）
- [ ] Android 构建验证（`flutter build apk`）
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`
- [ ] CI：覆盖率门禁
- [ ] 三 Service `_apiPost/Put/Delete` 提取为 mixin
- [ ] `analysis_options.yaml` 开启 `prefer_const_constructors` 等 lint
- [ ] GUI 测试并行化：16 个 pytest 错误修复（无 Flutter 进程时跳过标记）
- [ ] `flutter test` 全部通过 + `dart analyze` 零报错

## [v0.2] — 考核（规划中）

> 考核管理从教学管理分离，成为独立导航入口，覆盖完整考核流程。

### Added
- [ ] 考核导航独立：侧边栏新增「考核管理」tab
- [ ] 学生提交工作流：筛选/标记/提交内容
- [ ] 批量评分面板：全班集中评分 + 连续评分模式
- [ ] 成绩概览：统计卡片 / 分布图 / 导出
- [ ] 考试模式：题型（选择/填空/简答）+ 自动评分 + 计时
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`
- [ ] 三 Service `_apiPost/Put/Delete` 提取为 mixin
- [ ] `analysis_options.yaml` 开启 `prefer_const_constructors` 等 lint
- [ ] GUI 测试并行化：16 个 pytest 错误因无 Flutter 进程，加 CI 跳过标记

## [v0.3] — 班级和学员（规划中）

> 班级管理和学员体系完善，支持学员加入/退班、学习进度追踪。

### Added
- [ ] 班级 CRUD 完善：创建/编辑/删除/列表
- [ ] 学员管理：邀请加入/审核/退班/学员名单
- [ ] 班级仪表盘：统计卡片 / 进度分布 / 导出
- [ ] 学员学习进度追踪：个人学习记录 / 完成率 / 趋势

## [v0.0.6] — 已发布

> 班级/考核/评分基础 CRUD + 拖拽排序 + API 写回 + 仪表盘整合。

### Added
- [x] 班级/考核/评分 CRUD
- [x] 拖拽排序
- [x] API 写回
- [x] 仪表盘整合

## [v0.0.5] — 已发布

> Program/Course/Phase/Lesson 四级 CRUD + JSON 双轨互通。

### Added
- [x] 四级 CRUD（Program/Course/Phase/Lesson）
- [x] 发布/下架
- [x] JSON 双轨互通（导入/导出）
- [x] Sidebar 导航重构（底部导航 → 左侧导航）
- [x] Service 拆分
