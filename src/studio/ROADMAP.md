# ROADMAP — Studio

## 当前状态：v0.0.3 ✅

- **DataSource 策略模式**：`CourseDataService` 支持双数据源，`--dart-define=API_BASE_URL` 切换，单元测试覆盖
- **PreviewScreen 真实场景播放**：Scene/Step/Choice 完整交互，6 个 Widget 测试
- **发布**: [`studio/v0.0.3`](https://github.com/quanttide/qtcloud-course/releases/tag/studio/v0.0.3)

---

## v0.0.4 — GUI 测试 & 联调验证

**核心目标**：完成 GUI 自动化测试补充，首次 Provider ↔ Studio 联调验证通过。

### GUI 测试补充

- [ ] 更多交互测试（点击场景步骤、验证导航）
- [ ] CI 集成文档（runner 依赖安装清单）
- [ ] `smart_click` 模板管理脚本

### 联调验证

- [ ] `flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080` 正常加载
- [ ] Provider `go run ./cmd/server/` 配合验证
- [ ] 首次联调问题清单记录

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
