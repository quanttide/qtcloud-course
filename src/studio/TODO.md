# TODO — v0.0.4

## GUI 测试补充

### 代码

- [ ] 更多交互测试（点击场景步骤、验证导航）
- [ ] CI 集成文档（runner 依赖安装清单：xvfb-run / xdotool / ImageMagick / tesseract / OpenCV）
- [ ] `smart_click` 模板管理脚本（清除/更新缓存模板）

### 测试

- [ ] `pytest tests/test_studio.py -v` 全部通过

## 联调验证

- [ ] `flutter run -d linux` assets 模式正常
- [ ] `flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080` API 模式加载数据
- [ ] Provider 端 `go run ./cmd/server/` 正常启动
- [ ] 首次联调问题清单记录

---

## v0.0.3 回顾（已完成）

v0.0.3 全部任务已完成并发布。见 [CHANGELOG.md](./CHANGELOG.md)。

### DataSource 策略模式

- `CourseDataService` 双数据源（assets / API），`baseUrl` 参数切换
- `--dart-define=API_BASE_URL` 编译期注入
- `http` 依赖，MockClient 单元测试覆盖 API 模式
- `loading` / `error` 状态字段，支持部分加载失败展示

### PreviewScreen 真实场景播放

- Scene 标题展示、Step 逐步骤引导、Choice 跳转、验证提示、视频占位
- 6 个 Widget 测试覆盖场景切换全路径

### 发布

- [x] `pubspec.yaml` version `0.0.3`
- [x] `CHANGELOG.md` v0.0.3
- [x] Tag `studio/v0.0.3`
- [x] GitHub Release
