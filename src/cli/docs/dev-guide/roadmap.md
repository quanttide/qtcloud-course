# ROADMAP — CLI

> CLI 是 Studio 的验证层（Verification Layer）。每个 Studio 功能进入 Flutter UI 开发前，必须先能在 CLI 层面通过命令验证生产流程是否跑通。
>
> - **先 CLI，再 Studio**：CLI 验证通过后，再开始对应的 Flutter UI 实现
> - **命令即测试**：每条 CLI 子命令封装一条生产流程，可脚本化、可 CI 集成
> - **一一映射**：每个 Studio 版本有一份等价的 CLI 命令集，方便逐功能对照验证
>
> LMS 能力（考核、班级 / 学员）已迁移至 `qtcloud-learn`，本 scope 聚焦课程制作链路。

| CLI 版 | 验证目标（Studio） | 核心流程 |
|--------|-------------------|----------|
| v0.0 (已归档) | v0.0.5/v0.0.6 | AI 课程蓝图生成 |
| v0.1 (已发布) | v0.1 | 课程数据管线：蓝图 JSON → 校验 → Provider 导入/导出 |
| v0.2 (规划中) | v0.2 | 课程生产：上架 / 发布 / 供给学习云 |

## [v0.1] — 已发布（v0.1.0-alpha.4）

> **验证 Studio v0.1：课程数据管线。**
>
> 验证能力：AI 生成的结构化课程 JSON 可被校验、可被 Provider API 持久化、可被导出。这是 Studio Scene 编辑器 + 数据管线功能的前置条件。

### 已验证
- [x] `course` 子命令 + 提示词优化：输出 Program → Course → Phase → Lesson → Scene 五层结构化 JSON
- [x] `course --format json`：输出结构化 JSON，兼容 Studio 导入格式
- [x] `validate`：校验课程 JSON 数据结构完整性（schema 校验）
- [x] `import`：从蓝图 JSON 导入课程结构到 Provider API
- [x] `export`：从 Provider API 导出课程数据为 JSON
- [x] 环境配置统一（`QTCLOUD_API_BASE_URL` 默认 `http://localhost:8080`）
- [x] 单元测试：5 个测试覆盖 validate/json format/prompt
- [x] Mock 注入：`course::run` 接受 `Option<&LLM>`，通过 `MockHttpClient` 可单元测试

### CLI 验证流程（Studio v0.1 开发启动检查清单）

在开始 Studio v0.1 UI 开发前，先通过以下命令验证管线是否就绪：

```bash
# 1. 生成课程蓝图（结构化 JSON）
qtcloud-course course "Git 入门" --format json --output-path blueprint.json

# 2. 校验 JSON 完整性
qtcloud-course validate blueprint.json

# 3. 导入 Provider（确保 Provider 已启动）
qtcloud-course import blueprint.json

# 4. 导出验证导入结果
qtcloud-course export <program-id> --output-path roundtrip.json
```

若以上命令均通过，Studio v0.1 的数据管线已就绪，可以开始 Scene 编辑器 UI 开发。

## [v0.2] — 规划中

> **验证 Studio v0.2：课程生产链路。**
>
> 课程上架、发布与供给学习云。对齐根 ROADMAP v0.2。

### Added
- [ ] `publish`：批量发布/下架课程结构（草稿 → 审核 → 发布状态流转）
- [ ] `sync`：课程数据同步至 `qtcloud-learn`（学习云内容源）
- [ ] 视频上传验证：`upload video` 对接 Provider 视频上传 API

### CLI 验证流程（Studio v0.2 开发启动检查清单）

```bash
# 1. 发布课程
qtcloud-course publish --program-id <id>

# 2. 同步课程到学习云
qtcloud-course sync --program-id <id> --target qtcloud-learn

# 3. 上传互动视频
qtcloud-course upload video --program-id <id> --file intro.mp4
```

## [v0.0] — 已归档

> 初始原型。AI 生成课程蓝图，验证 LLM → 课程结构的转换链路。对应 Studio v0.0.5/v0.0.6 的课程概念验证。

### Added
- [x] `course` 子命令：AI 生成课程蓝图
- [x] `--input-path`：传入原始资料作为上下文
- [x] `--output-path`：直接写入文件
- [x] `src/lib.rs`：暴露 `course` 模块作为库接口
