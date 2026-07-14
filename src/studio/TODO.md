# TODO — v0.0.3

## DataSource 策略模式

在 `CourseDataService` 内部增加双数据源切换，不改调用方接口。

### 代码

- [ ] 添加 `http` 依赖到 `pubspec.yaml`
- [ ] `CourseDataService` 增加 `baseUrl` 参数：
  - `null` → 从 `assets/` 加载 JSON（现有行为，不变）
  - `非 null` → 从 `http://$baseUrl` 调用 Provider API
- [ ] `CourseDataService._loadFromAssets()` — 现有 `load()` 代码，原封不动搬入
- [ ] `CourseDataService._loadFromApi()` — 新实现：HTTP GET `/programs` + `/classes`
- [ ] `CourseDataService.loadLesson()` 同样支持双数据源：
  - assets 模式：`assets/$lessonId.json`（现有行为）
  - API 模式：`GET /lessons/{lessonId}`
- [ ] 默认构造 `CourseDataService()` 无参，保持 assets 模式
- [ ] `--dart-define=API_BASE_URL` 编译期注入

### 测试

- [ ] 新增单元测试覆盖 API 数据源（mock HTTP 响应）
- [ ] `flutter test` 全部通过

---

## PreviewScreen 真实场景播放

### 代码

- [ ] Scene 标题展示
- [ ] Step 逐步骤文字引导（`Step.content`）
- [ ] Choice 跳转支持（场景间导航，`Choice.targetSceneId`）
- [ ] 验证提示展示（`verifyTip`）
- [ ] 视频播放占位（展示 `videoUrl`，未来集成真实播放器）

### 测试

- [ ] Widget 测试覆盖 Step 渲染
- [ ] Widget 测试覆盖 Choice 跳转

---

## GUI 测试补充

### 代码

- [ ] 更多交互测试（点击场景步骤、验证导航）
- [ ] CI 集成文档（runner 依赖安装清单：xvfb-run / xdotool / ImageMagick / tesseract / OpenCV）
- [ ] `smart_click` 模板管理脚本（清除/更新缓存模板）

### 测试

- [ ] `pytest tests/test_studio.py -v` 全部通过

---

## 联调验证

- [ ] `flutter run -d linux` assets 模式正常
- [ ] `flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080` API 模式加载数据
- [ ] Provider 端 `go run ./cmd/server/` 正常启动
- [ ] 首次联调问题清单记录

---

## 发布

- [ ] 在 `pubspec.yaml` 中更新版本号至 `0.0.3`
- [ ] 运行 `flutter test` 全部通过
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.3`

---

## v0.0.2 回顾（已完成）

v0.0.2 全部任务已完成并发布。见 [CHANGELOG.md](./CHANGELOG.md)。
