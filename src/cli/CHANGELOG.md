# CHANGELOG

## [0.1.0-alpha.6] - 2026-07-16

### Added
- `course design` 子命令：基于已有课程蓝图 + 人类指示迭代修改
- `lesson blueprint` 子命令：从 Markdown 生成课时 Scene 级设计
- `lesson design` 子命令：基于已有课时蓝图 + 人类指示迭代修改
- `LessonBlueprint` 类型：含 scenes 的完整课时结构
- `validate_lesson_json`：课时蓝图 JSON 校验

### Changed
- `course blueprint` 输出改为 Program → Course → Phase → Lesson 四级结构（不含 Scene）
- `types.rs`：分离 `CourseBlueprint`（无 scenes）和 `LessonBlueprint`（含 scenes）
- `course::run` 拆分为 `run_blueprint` 和 `run_design`
- `lesson` 模块：新增 `run_blueprint` 和 `run_design`

## [0.1.0-alpha.5] - 2026-07-16

### Changed
- 命令简化为 `course blueprint --from <md> --to <json>`
- 移除 topic 位置参数，主题从文件名推断
- 移除 `--format` 标记，始终输出结构化 JSON
- 移除 `--output-path`，改为 `--to` 必选参数
- 移除 `--input-path`，改为 `--from` 必选参数
- 移除 validate/import/export 子命令
- 提示词优化：区分教学目标和工具演示

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
