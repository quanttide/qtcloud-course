# 测试策略

## 单元测试

- `test/models/` — 验证 `fromJson` / `copyWith` 的正确性，覆盖字段解析、默认值、缺省行为
- `test/services/` — 验证 DataService 统计方法和数据加载逻辑
- 运行：`flutter test test/models/ test/services/`

## Widget 测试

- `test/screens/` — 验证组件渲染和交互展开逻辑
- 运行：`flutter test test/screens/`

## 集成测试

- `integration_test/` — 验证应用启动、页面跳转、试听全流程
- 运行：`flutter test integration_test/`（需要模拟器/真机）
