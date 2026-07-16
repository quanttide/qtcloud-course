# CHANGELOG


## [0.1.0-beta.3] - 2026-07-17

Fixed: 补充Cargo.toml中缺失的描述、许可证和仓库地址元数据。  
Changed: 添加单元测试和CLI集成测试，并将代码测试覆盖率从37.73%提升至45.68%。
## [0.1.0-beta.2] - 2026-07-17

### Fixed
- lesson preview: 所有场景均作为主场景渲染，exception 嵌套在父场景下
- lesson preview: truncate() 处理多字节 UTF-8 字符边界 panic
- HTML 改为基于场景文件渲染，不再依赖课时蓝图的场景拆分
- CI workflows: actions/checkout 和 upload-artifact 版本修正


## [0.1.0-beta.1] - 2026-07-17

### Added
- `lesson blueprint` 两遍 LLM 调用（切场景 → 编排）
- `lesson design` 子命令
- `scene blueprint` 和 `scene design` 子命令
- `course preview` / `lesson preview` / `scene preview` 命令（JSON→HTML）
- preview `--template` 参数：支持自定义 HTML 模板
- CI workflows：build-cli / publish-cli

### Changed
- 场景类型改为操作步骤（step），异常通过嵌套 exception 字段表达
- `course blueprint` 输出不再含 Scene 层级
- 移除所有 `duration_minutes`（时长是录制实测值，非设计数据）
- CHANGELOG 按 Keep a Changelog 规范重排
- docs 拆分为 course/lesson/scene 三份独立文档

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
