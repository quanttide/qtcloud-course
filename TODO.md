# TODO

跨组件任务，不归属于单一 scope。

## GUI 测试补充

需要 Studio GUI 框架 + Provider API 配合的端到端测试。

### 任务

- [ ] CI 集成文档（runner 依赖安装清单：xvfb-run / xdotool / ImageMagick / tesseract / OpenCV）
- [ ] `smart_click` 模板管理脚本（清除/更新缓存模板）
- [ ] `pytest tests/test_studio.py -v` 全部通过

## 联调验证

首次 Provider ↔ Studio 前后端联调。

- [ ] `flutter run -d linux` assets 模式正常
- [ ] `flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080` API 模式加载数据
- [ ] Provider 端 `go run ./cmd/server/` 配合验证
- [ ] 首次联调问题清单记录
