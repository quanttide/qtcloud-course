# ROADMAP — CLI

> CLI 版本与产品版本对齐关系：

| 产品版 | CLI 版 | 目标 |
|--------|--------|------|
| v0.1 课程制作 | v0.1 | 结构化输出 + validate/import/export |
| v0.2 考核 | v0.2 | sync/publish 子命令 |
| v0.3 班级和学员 | — | — |

## [0.1.0-alpha.3] — 已发布

### Added
- [x] `blueprint` 子命令：AI 生成课程蓝图
- [x] `--input-path`：传入原始资料作为上下文
- [x] `--output-path`：直接写入文件
- [x] `src/lib.rs`：暴露 `blueprint` 模块作为库接口

## [v0.1] — 进行中

> 从"蓝图生成器"升级为"课程数据工作台"。对齐产品级 **v0.1 课程制作**。

### Added
- [ ] **结构化输出**：`blueprint --format json` 输出结构化 JSON，兼容 Studio 导入格式
- [ ] **子命令扩展**：`validate` — 校验课程 JSON 数据结构完整性
- [ ] **子命令扩展**：`import` — 从蓝图 JSON 生成 Studio 可加载的 Program 结构
- [ ] **子命令扩展**：`export` — 从 Provider API 导出课程数据为 JSON

### Changed
- [ ] blueprint 提示词优化：输出结构化课程框架（Program → Course → Phase → Lesson 层级）

### TechDebt
- [ ] **测试覆盖**：`blueprint.rs` + `main.rs` 无对应 `*_test.rs`，当前零测试
- [ ] **mock 注入**：`blueprint::run` 硬依赖 `quanttide_agent::LLM`，无法单元测试

## [v0.2] — 规划中

> 集成到考核流程。对齐产品级 **v0.2 考核**。

### Added
- [ ] `sync` 子命令：CLI ↔ Provider API 双向同步
- [ ] `publish` 子命令：批量发布/下架课程结构
- [ ] 本地缓存：离线工作，在线同步
