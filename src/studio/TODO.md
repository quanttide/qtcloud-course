# TODO — v0.0.2

## 数据模型 Phase / Scene / Step / Choice

### 代码

- [x] 新建 `lib/models/phase.dart` — Phase（id/name/sortOrder/lessons: List<Lesson>）
- [x] 新建 `lib/models/scene.dart` — Scene（id/name/title/steps/choices/verifyTip），Step（order/content），Choice（label/targetSceneId）
- [x] 修改 `lib/models/program.dart` — Course.lessons → Course.phases: List<Phase>；Lesson 新增 sortOrder 和 scenes: List<Scene>
- [x] 修改 `lib/services/data_service.dart` — 新增 `loadLesson(String lessonId)` 按需加载单课 Scene/Step 详情

### 测试

- [x] 新建 `test/models/phase_test.dart` — Phase fromJson/copyWith 单元测试
- [x] 新建 `test/models/scene_test.dart` — Scene/Step/Choice fromJson 单元测试
- [x] 修改 `test/models/program_test.dart` — Course JSON 从 `lessons` 改为 `phases`；Lesson 增加 scenes/sortOrder 断言
- [x] 新建 `test/services/` 目录
- [x] 新建 `test/services/data_service_test.dart` — DataService 统计逻辑单元测试（loadLesson 由集成测试覆盖）

---

## 课程研发页：Phase → Scene → Step 展开

### 代码

- [x] 修改 `lib/screens/program_screen.dart`
  - Course tile 展开后显示 Phase 列表（原有 Lesson 列表改为 Phase 列表）
  - Phase tile 展开后显示 Lesson 列表
  - Lesson tile 展开后显示 Scene 列表（需调用 DataService.loadLesson 加载）
  - Scene tile 展开后显示 Step 列表 + 验证提示
  - Lesson 行末增加"试听"按钮
  - 新增 `_PhaseTile`、`_SceneTile`、`_StepTile` 子 Widget

### 测试

- [x] 修改 `test/screens/program_screen_test.dart` — 适配 Phase → Lesson → Scene 嵌套，测试展开至 Scene 层级
- [x] 断言"试听"按钮存在

---

## 开发文档（doc/）

### 文档

- [x] 新建 `doc/README.md` — 开发文档入口，说明子目录结构
- [x] 新建 `doc/architecture.md` — Studio 分层架构说明（Models → Services → Screens）
- [x] 新建 `doc/data-model.md` — 数据模型层级和 JSON 字段对照表
- [x] 新建 `doc/testing.md` — 测试策略说明（单元测试 vs 集成测试的职责划分、运行方式）

---

## 试听预览页

### 代码

- [x] 新建 `lib/screens/preview_screen.dart` — 占位页，显示 lessonId

### 测试

- [x] 新建 `test/screens/preview_screen_test.dart` — 渲染占位页

---

## 数据准备

### 代码

- [x] 复制 `data/profile/vibe-coding/lesson1.json` 到 `assets/lesson1.json`
- [x] 修改 `pubspec.yaml` — 在 assets 段添加 `assets/lesson1.json`

### 测试

- [x] DataService 测试覆盖（统计逻辑单元测试 + 加载逻辑集成测试）

---

## 发布

- [x] 在 `pubspec.yaml` 中更新版本号至 `0.0.2`
- [x] 运行 `flutter test` 确认全部通过（58/58）
- [ ] 创建 git tag `studio/v0.0.2`
- [x] 更新 `CHANGELOG.md` 确认完整
