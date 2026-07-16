# ROADMAP — CLI

> CLI 版本与 Studio 一一对应，每个里程碑提供 CLI 层面等价能力。

| CLI 版 | Studio 版 | 目标 |
|--------|-----------|------|
| v0.0 (已发布) | v0.0.5/v0.0.6 | course 课程生成 |
| v0.1 | v0.1 | 课程制作：结构化数据 + 校验 + 导入导出 |
| v0.2 | v0.2 | 考核：考核数据管理 |
| v0.3 | v0.3 | 班级和学员：成员与进度管理 |

## [v0.0] — 已发布

> AI 生成课程蓝图。对应 Studio 基础 CRUD + 预览阶段。

### Added
- [x] `course` 子命令：AI 生成课程蓝图
- [x] `--input-path`：传入原始资料作为上下文
- [x] `--output-path`：直接写入文件
- [x] `src/lib.rs`：暴露 `course` 模块作为库接口

## [v0.1] — 课程制作（进行中）

> 从"蓝图生成器"升级为"课程数据工作台"。CLI 输出结构化 JSON，Studio 可直接导入；CLI 也可直接与 Provider API 交互。

### Added
- [ ] `course --format json`：输出结构化 JSON，兼容 Studio 导入格式
- [ ] `validate`：校验课程 JSON 数据结构完整性（schema 校验）
- [ ] `import`：从蓝图 JSON 导入课程结构到 Provider API
- [ ] `export`：从 Provider API 导出课程数据为 JSON
- [ ] course 提示词优化：输出结构化课程框架（Program → Course → Phase → Lesson → Scene 层级）
- [ ] 环境配置统一（`api_base_url` 默认 `http://localhost:8080`）

### TechDebt
- [ ] **测试覆盖**：`course.rs` + `main.rs` 无对应 `*_test.rs`，当前零测试
- [ ] **mock 注入**：`course::run` 硬依赖 `quanttide_agent::LLM`，无法单元测试

## [v0.2] — 考核（规划中）

> 考核数据管理。CLI 层面完成 Studio v0.2 考核功能的等价操作。

### Added
- [ ] `assessment create`：创建考核（指定班级、类型、分值、截止日期）
- [ ] `assessment list`：按班级列出考核
- [ ] `assessment submit`：批量提交学生作答（从 CSV/JSON 导入）
- [ ] `assessment grade`：批量评分 + 导出成绩单
- [ ] `assessment stats`：统计概览（平均分/及格率/分布）

## [v0.3] — 班级和学员（规划中）

> 班级和学员管理。CLI 层面完成 Studio v0.3 班级和学员功能的等价操作。

### Added
- [ ] `class create`：创建班级
- [ ] `class list`：列出班级
- [ ] `student invite`：邀请学员加入班级（从 CSV/JSON 批量导入）
- [ ] `student list`：查看学员名单
- [ ] `student progress`：查询学员学习进度
- [ ] `sync`：CLI ↔ Provider API 双向同步（离线编辑，在线同步）
- [ ] `publish`：批量发布/下架课程结构
