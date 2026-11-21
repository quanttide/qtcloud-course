# ROADMAP — Studio

> Studio 定位：课程制作工具。LMS 能力（考核、班级 / 学员）已迁移至 `qtcloud-learn`，本 scope 聚焦课程制作。

## [v0.3] — 课时工作台（2026-11-21 落地）

> 单页两栏：左写课时 Markdown、右预览学员端形态。起因是课时内容三份手抄、改一句要发一个 patch（AI创意第 3 步连发 0.2.4/0.2.5/0.2.6）——把对齐挪到发版之前。

### Added
- [x] `WorkbenchScreen`：打开 `data/profile/<course>/lessonN-*/` 正本目录，编辑 + 保存写回
- [x] `lesson_md.dart`：Markdown → Lesson 解析，规则唯一，五种块（note/copy/code/link/image）+ tip/foot
- [x] `lesson_preview.dart`：学员端形态渲染，结构照 qtclass-lite 的 `LessonDetail.tsx`
- [x] 解析失败当场报错（缺标题 / 围栏未闭合 / 块悬空 / 未知类型）

### Changed
- [x] 收敛旧多屏（ProgramScreen / SceneEditorScreen / PreviewScreen、Sidebar）与 Program / Phase / Scene 模型——服务端 0.1.1-alpha.4 已删这两级，编辑器不再维护第二棵树
- [x] README 由 Flutter 脚手架样板改为工作台说明

### 下一步
- [ ] `index.json` 同步与 steps ↔ scenes 对应
- [ ] 三门新课在 profile 补课时目录
- [x] `studio/*` 部署 workflow + 站点 IaC（桶 qtcloud-course-studio、域名 studio.course.cloud.quanttide.com）
- [ ] 远程推送 provider

## [v0.1] — 课程制作（进行中）

> Scene 编辑器 + 分支选项 + 本地持久化。Studio 作为独立本地软件，不依赖 Provider/CLI。

### Added
- [x] Scene 编辑器：创建/编辑/删除/排序场景和步骤
- [x] 分支选项 UI：步骤内分支选择、跳转目标场景配置
- [x] 本地模式默认：不再依赖 Provider API，默认读取本地 JSON
- [x] 本地持久化：编辑内容自动保存到 `~/.qtcloud-course/data/`
- [x] JSON 导出/导入：文件选择器导入导出课程结构
- [x] `dart analyze` 零报错
- [x] `flutter test` 165 个全通过
- [ ] 导入预览 + JSON schema 校验
- [ ] 环境配置统一（`api_base_url`、`data_dir`）
- [ ] iOS/Android 构建验证
- [ ] CI：自动构建 + 测试 + 覆盖率门禁
- [ ] Service mixin 重构
- [ ] GUI 测试并行化

## [v0.2] — 课程生产（规划中）

> 制作侧生产链路：上架、素材管理，对齐根 ROADMAP v0.2。

### Added
- [ ] 课程上架流程（草稿 → 审核 → 发布）
- [ ] 互动视频上传与管理（对接 Provider 视频上传 API）
- [ ] 课程数据供给 `qtcloud-learn`（学习云内容源）

## [v0.0.6] — 已发布

> 课程结构 CRUD + 拖拽排序 + API 写回 + 仪表盘整合。

### Added
- [x] 课程结构 CRUD
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
