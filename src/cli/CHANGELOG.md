# CHANGELOG

## [0.1.0-alpha.4] - 2026-07-16

### Changed
- `blueprint` 子命令重命名为 `course`，对应模块和文件同步改名

### Added
- `course --format`：输出结构化 JSON，兼容 Studio 导入格式
- `validate` 子命令：校验课程 JSON 数据结构完整性
- `import` 子命令：从蓝图 JSON 导入课程结构到 Provider API
- `export` 子命令：从 Provider API 导出课程数据为 JSON
- 提示词优化：输出 Program → Course → Phase → Lesson → Scene 五层结构
- 环境配置统一：`QTCLOUD_API_BASE_URL`（默认 `http://localhost:8080`）
- 单元测试：5 个测试覆盖 validate/json format/prompt
- Mock 注入：`course::run` 接受 `Option<&LLM>`，测试通过 `MockHttpClient` 注入

## [0.1.0-alpha.3] - 2026-07-04

### Added
- `src/lib.rs`，暴露 `blueprint` 模块作为库接口

## [0.1.0-alpha.2] - 2026-07-04

### Added
- `--input-path` 参数：提供原始资料作为上下文
- `--output-path` 参数：直接写入文件

## [0.1.0-alpha.1] - 2026-07-04

### Added
- 无状态 CLI，支持 `blueprint` 子命令
- 通过 `quanttide-agent` 调用 DeepSeek 生成课程蓝图
