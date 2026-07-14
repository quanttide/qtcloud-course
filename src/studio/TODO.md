# TODO — Studio

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
