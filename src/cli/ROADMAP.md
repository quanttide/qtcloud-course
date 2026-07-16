# ROADMAP — CLI

> CLI 是 Studio 的验证层（Verification Layer）。每个 Studio 功能进入 Flutter UI 开发前，必须先能在 CLI 层面通过命令验证生产流程是否跑通。
>
> - **先 CLI，再 Studio**：CLI 验证通过后，再开始对应的 Flutter UI 实现
> - **命令即测试**：每条 CLI 子命令封装一条生产流程，可脚本化、可 CI 集成
> - **一一映射**：每个 Studio 版本有一份等价的 CLI 命令集，方便逐功能对照验证

| CLI 版 | 验证目标（Studio） | 核心流程 |
|--------|-------------------|----------|
| v0.0 (已归档) | v0.0.5/v0.0.6 | AI 课程蓝图生成 |
| v0.1 (已发布) | v0.1 | 课程数据管线：蓝图 JSON → 校验 → Provider 导入/导出 |
| v0.2 | v0.2 | 考核全流程：创建 → 提交 → 评分 → 统计 |
| v0.3 | v0.3 | 班级/学员 + 认证 + 进度追踪 |

## [v0.1] — 已发布（v0.1.0-beta.1）

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

> **验证 Studio v0.2：考核全流程。**
>
> Studio v0.2 新增考核导航、学生提交、批量评分、成绩概览、考试模式。CLI 需先验证每步流程可脱离 UI 独立跑通。

### Added
- [ ] `assessment create`：创建考核（指定班级、类型、分值、截止日期）
    - 验证 Studio「考核导航独立」的数据入口
- [ ] `assessment list`：按班级列出考核
- [ ] `assessment submit`：批量提交学生作答（从 CSV/JSON 导入）
    - 验证 Studio「学生提交工作流」的数据路径
- [ ] `assessment grade`：批量评分 + 导出成绩单
    - 验证 Studio「批量评分面板」的评分流程
- [ ] `assessment stats`：统计概览（平均分/及格率/分布）
    - 验证 Studio「成绩概览」的统计计算
- [ ] `assessment submit --exam`：考试模式作答提交
    - 验证 Studio「考试模式」的题型数据格式

### CLI 验证流程（Studio v0.2 开发启动检查清单）

```bash
# 1. 创建考核
qtcloud-course assessment create --class-id <id> --type homework --max-score 100

# 2. 批量提交（模拟学生作答）
qtcloud-course assessment submit --assessment-id <id> --from submissions.csv

# 3. 批量评分
qtcloud-course assessment grade --assessment-id <id> --from grades.csv

# 4. 查看统计概览
qtcloud-course assessment stats --assessment-id <id>
```

## [v0.3] — 规划中

> **验证 Studio v0.3：班级和学员体系。**
>
> Studio v0.3 新增班级管理、学员管理、认证权限、课程上架、学生端播放器。CLI 需先验证各管理流程和 API 数据的完整性。

### Added
- [ ] `class create`：创建班级
    - 验证 Studio「班级 CRUD」的数据入口
- [ ] `class list`：列出班级
- [ ] `student invite`：邀请学员加入班级（从 CSV/JSON 批量导入）
    - 验证 Studio「学员管理」的加入流程
- [ ] `student list`：查看学员名单
- [ ] `student progress`：查询学员学习进度
    - 验证 Studio「学员学习进度追踪」的数据接口
- [ ] `publish`：批量发布/下架课程结构
    - 验证 Studio「课程上架流程」的状态流转
- [ ] `auth login`：飞书登录认证（获取 token）
    - 验证 Studio「用户认证」的登录流程

### CLI 验证流程（Studio v0.3 开发启动检查清单）

```bash
# 1. 认证登录
qtcloud-course auth login --provider feishu

# 2. 创建班级
qtcloud-course class create --name "2025 春季班"

# 3. 批量邀请学员
qtcloud-course student invite --class-id <id> --from students.csv

# 4. 查看学员进度
qtcloud-course student progress --class-id <id> --student-id <uid>

# 5. 发布课程
qtcloud-course publish --program-id <id>
```

## [v0.0] — 已归档

> 初始原型。AI 生成课程蓝图，验证 LLM → 课程结构的转换链路。对应 Studio v0.0.5/v0.0.6 的课程概念验证。

### Added
- [x] `course` 子命令：AI 生成课程蓝图
- [x] `--input-path`：传入原始资料作为上下文
- [x] `--output-path`：直接写入文件
- [x] `src/lib.rs`：暴露 `course` 模块作为库接口
