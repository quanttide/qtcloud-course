# ROADMAP — Studio

## 当前状态：v0.0.2 ✅

Studio 已支持 Program → Course → Phase → Lesson → Scene → Step 六级编排树，Lesson 行末带"试听"按钮跳转预览页（占位）。数据通过 `DataService.loadLesson` 按需加载。集成测试覆盖启动、页面切换和试听全流程。

GUI 自动化测试框架就位（`utils/gui.py`），支持 Xvfb 截图 / OCR / OpenCV 模板匹配。

---

## v0.0.3 — 前后端联调

对应产品级 v0.1.0 里程碑。详见 [`ROADMAP.md`](../../ROADMAP.md)。

**核心目标**：首次与 Provider API 联调，PreviewScreen 从占位变为真实内容。

### 1. DataSource 策略模式

在 `CourseDataService` 内部增加双数据源切换，不改调用方。

- [ ] `CourseDataService` 支持 `baseUrl` 参数：
  - `null` → 从 `assets/` 加载 JSON（现有行为，不变）
  - `非 null` → 从 `http://$baseUrl` 调用 Provider API
- [ ] 加载路径保持不变：`load()` / `loadLesson(String lessonId)`
- [ ] 添加 `http` 依赖
- [ ] `--dart-define=API_BASE_URL=http://localhost:8080` 编译期注入
- [ ] 新增单元测试覆盖 API 数据源

### 2. PreviewScreen 真实场景播放

- [ ] Scene 标题展示
- [ ] Step 逐步骤文字引导（`Step.content`）
- [ ] Choice 跳转（场景间导航）
- [ ] 验证提示展示（`verifyTip`）
- [ ] 视频播放占位（展示 `videoUrl`，未来集成真实播放器）

### 3. GUI 测试补充

- [ ] 更多交互测试（点击场景步骤、验证导航）
- [ ] CI 集成文档（runner 依赖安装清单：xvfb-run / xdotool / ImageMagick / tesseract / OpenCV）
- [ ] `smart_click` 模板管理脚本（清除/更新缓存模板）

### 4. 本地运行不变

```
# assets 模式（与现在完全相同）
flutter run -d linux

# API 模式（联调）
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080
```

### 交付标准

```
flutter test                              # ✅ 全部通过
flutter run -d linux                       # ✅ assets 模式正常
flutter run -d linux --dart-define=...     # ✅ API 模式加载数据
pytest tests/test_studio.py -v            # ✅ GUI 测试通过
```

---

## v0.1.0 — 运营后台可用

对应产品级 v0.2.0 里程碑。

- [ ] 教学管理页：班级详情从 API 加载
- [ ] 仪表盘指标从 API 加载（取代本地统计）
- [ ] Windows / macOS 构建验证
- [ ] CI pipeline：push 自动跑测试
- [ ] 截图对比测试（OpenCV 模板匹配）

---

## v0.2.0 — 课程交付闭环

对应产品级 v0.3.0 里程碑。

- [ ] 讲师端：课程编辑界面（拖拽排序、内容管理）
- [ ] 学生端：课程学习界面（视频播放、步骤引导）
- [ ] 课堂互动（提问、反馈）
- [ ] 离线学习支持（缓存已加载课时）

---

## 架构演进

```
v0.0.2                  v0.0.3                      v0.1.0
本地 assets JSON  ──→   双数据源（assets/API） ──→   默认 API
预览占位页        ──→   真实场景播放            ──→   课程编辑
Linux only        ──→   Linux                   ──→   Linux/mac/Windows
手动测试          ──→   脚本测试                ──→   CI 自动化
```
