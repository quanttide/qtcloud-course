# 测试策略

## 单元测试

- `test/models/` — 验证 `fromJson` / `copyWith` 的正确性，覆盖字段解析、默认值、缺省行为
- `test/services/` — 验证 DataService 统计方法和数据加载逻辑
- 运行：`flutter test test/models/ test/services/`

## Widget 测试

- `test/screens/` — 验证组件渲染和交互展开逻辑
- 运行：`flutter test test/screens/`

## 集成测试

当前无集成测试。应用启动、页面跳转、试听全流程由 Widget 测试覆盖（见上）。
如需端到端测试（如平台通道、真实 I/O），可添加 `flutter_driver` 或 `integration_test` 测试，需要模拟器/真机运行。
