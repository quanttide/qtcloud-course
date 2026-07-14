# TODO — v0.0.4

## 底部导航 → 侧边导航

### 代码

- [ ] 新建 `lib/widgets/sidebar.dart` — Sidebar 组件（固定 240px，`Icons.home` / `Icons.school` / `Icons.group`）
- [ ] `MainShell` 布局从 `bottomNavigationBar` 改为 `Row(Sidebar, Expanded(Content))`
- [ ] 路由状态：`_currentRoute` 区分 `tab` / `preview(lessonId)`，Content 区域切换 `IndexedStack` 或 `PreviewScreen`
- [ ] `PreviewScreen` 迁出独立 `Scaffold`（AppBar 由 MainShell 控制或保留但隐藏 Sidebar）

### 测试

- [ ] 更新 widget 测试适配新布局
- [ ] GUI 测试：更新 `smart_click` 模板截图（窗口结构变更，全套重新录制）
- [ ] `flutter test` 全部通过

---

## GUI 测试补充

跨组件端到端测试。

### 代码

- [ ] CI 集成文档（runner 依赖安装清单：xvfb-run / xdotool / ImageMagick / tesseract / OpenCV）
- [ ] `smart_click` 模板管理脚本（清除/更新缓存模板）

### 测试

- [ ] `pytest tests/test_studio.py -v` 全部通过

---

## 联调验证

首次 Provider ↔ Studio 前后端联调。

- [ ] `flutter run -d linux` assets 模式正常
- [ ] `flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080` API 模式加载数据
- [ ] Provider 端 `go run ./cmd/server/` 配合验证
- [ ] 首次联调问题清单记录

---

## 发布

- [ ] 在 `pubspec.yaml` 中更新版本号至 `0.0.4`
- [ ] 运行 `flutter test` 全部通过
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.4`
