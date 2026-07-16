# TODO

## 集成测试覆盖完整场景 ✅ 已完成

> 10 个集成测试已实现并全部通过，覆盖 validate 边界、import/export 交互、完整管线 roundtrip。

### 已实现的基础设施

- [x] **Mock Provider 服务器**：`tests/integration.rs` 中基于 `TcpListener` 的轻量 HTTP mock，支持 POST/GET 模拟 import/export
- [x] **测试数据夹具**：`tests/fixtures/valid_blueprint.json` + `invalid_blueprint.json`

### 已实现的集成测试

#### 场景 1：validate 边界情况

- [x] `test_validate_valid_fixture` — 合法 fixture 校验通过
- [x] `test_validate_invalid_fixture` — 非法 fixture 检测到 title 错误
- [x] `test_validate_empty_courses_array` — 空 courses 数组合法
- [x] `test_validate_deeply_nested_structure` — 深层嵌套合法
- [x] `test_validate_missing_scenes` — scenes 可选，不报错

#### 场景 2：import/export 与 Provider 交互

- [x] `test_import_sends_correct_request` — 验证 import POST JSON 到 `/api/v1/programs`
- [x] `test_import_export_roundtrip` — 导入后导出，验证 roundtrip 数据一致性
- [x] `test_import_connection_refused` — Provider 未启动时友好错误提示
- [x] `test_export_nonexistent_program` — 导出不存在的 program 失败

#### 场景 3：CLI 核心逻辑可处理 fixture

- [x] `test_validate_via_cli_entrypoint` — 通过 CLI 入口函数校验合法/非法 fixture

### CI 集成

- [x] `cargo test` 包含所有集成测试
- [x] 集成测试不依赖外部网络（全部 mock）
- [x] 测试运行时间 < 5 秒（实际 0.05s）

## 待办

（暂无）
