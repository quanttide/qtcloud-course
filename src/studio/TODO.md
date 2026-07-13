# TODO — v0.0.2

## 数据模型 Phase / Scene / Step / Choice

### 代码

- [ ] 新建 `lib/models/phase.dart` — Phase（id/name/sortOrder/lessons）
- [ ] 新建 `lib/models/scene.dart` — Scene（id/name/title/steps/choices/verifyTip）+ Step（order/content）+ Choice（label/targetSceneId）
- [ ] 修改 `lib/models/program.dart` — Course 的 `lessons` 改为 `phases: List<Phase>`，fromJson/copyWith 同步更新
- [ ] 修改 `lib/services/data_service.dart` — 新增 `lessonJson` 加载方法（参考 `data/profile/vibe-coding/lesson1.json`）

### 测试

- [ ] 新建 `test/models/phase_test.dart` — Phase fromJson/copyWith 单元测试
- [ ] 新建 `test/models/scene_test.dart` — Scene/Step/Choice fromJson 单元测试
- [ ] 修改 `test/models/program_test.dart` — Course JSON 从 `lessons` 改为 `phases`，增加 Phase 嵌套断言
- [ ] 新建 `test/services/data_service_test.dart` — DataService 加载 lesson JSON 测试

### 文档

- [ ] 更新 `CHANGELOG.md` — 添加 v0.0.2 条目

---

## 课程研发页：Phase → Scene → Step 展开

### 代码

- [ ] 修改 `lib/screens/program_screen.dart`
  - Course tile 展开后显示 Phase 列表（原有 Lesson 列表改为 Phase 列表）
  - Phase tile 展开后显示 Lesson 列表
  - Lesson tile 展开后显示 Scene 列表
  - Scene tile 展开后显示 Step 列表 + 验证提示
  - Lesson 行末增加"试听"按钮

### 测试

- [ ] 修改 `test/screens/program_screen_test.dart` — 适配 Phase → Lesson 嵌套，测试展开至 Scene 层级
- [ ] 断言"试听"按钮存在

### 文档

- [ ] 更新 `CHANGELOG.md` — 同上

---

## 集成测试（integration_test/）

### 代码

- [ ] 配置 `integration_test` 依赖（`pubspec.yaml` dev_dependencies 添加 `integration_test` + `flutter_test`）
- [ ] 新建 `integration_test/app_test.dart` — 应用启动 + 页面跳转集成测试
- [ ] 新建 `integration_test/preview_test.dart` — 从课程研发页点击"试听"到预览页全流程
  - 加载 `lesson1.json` 构造测试数据
  - 模拟场景切换、步骤高亮、完成页呈现

### 文档

- [ ] 更新 `CHANGELOG.md` — 同上

---

## 开发文档（doc/）

### 文档

- [ ] 新建 `doc/README.md` — 开发文档入口，说明子目录结构
- [ ] 新建 `doc/architecture.md` — Studio 分层架构说明（Models → Services → Screens）
- [ ] 新建 `doc/data-model.md` — 数据模型层级和 JSON 字段对照表
- [ ] 新建 `doc/testing.md` — 测试策略说明（单元测试 vs 集成测试的职责划分、运行方式）
- [ ] 更新 `CHANGELOG.md` — 同上

---

## 试听预览页

### 代码

- [ ] 新建 `lib/screens/preview_screen.dart` — 一个全屏的"课堂页面"
  - 左侧视频占位 + 场景标题栏
  - 右侧步骤面板（场景导航 + 步骤列表 + 验证提示 + 继续按钮）
  - 最后一个场景显示完成页
  - 数据源：从 DataService 获取当前 Lesson 的 Scene/Step 数据
  - 参考 `data/profile/vibe-coding/lesson1.html` 的布局和交互

### 测试

- [ ] 新建 `test/screens/preview_screen_test.dart` — 测试场景切换、步骤高亮、完成页
- [ ] 设置 test data：构造含 2-3 个 Scene 的 Lesson 数据

### 文档

- [ ] 更新 `CHANGELOG.md` — 同上

---

## 数据准备

### 代码

- [ ] 复制 `data/profile/vibe-coding/lesson1.json` 到 `assets/lesson1.json`
- [ ] 修改 `pubspec.yaml` — 在 assets 段添加 `assets/lesson1.json`

### 测试

- [ ] DataService 测试覆盖 lesson JSON 的完整解析（见上）

---

## 发布

- [ ] 在 `pubspec.yaml` 中更新版本号至 `0.0.2`
- [ ] 运行 `flutter test` 确认全部通过
- [ ] 创建 git tag `studio/v0.0.2`
- [ ] 更新 `CHANGELOG.md` 确认完整
