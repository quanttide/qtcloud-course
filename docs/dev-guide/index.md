# 开发指南

量潮课程云的开发指引。

## 入门

1. 阅读 [specification/index.md](../../specification/index.md) 了解领域架构
2. 阅读 [specification/course/index.md](../../specification/course/index.md) 了解课程树模型
3. 查看 [studio ROADMAP](../../../src/studio/ROADMAP.md) 了解当前开发目标

## 技术映射

| 领域实体 | 代码位置 | 数据源 |
|---------|---------|--------|
| Program | `lib/models/program.dart` | assets JSON / API |
| Course | `lib/models/program.dart` | assets JSON / API |
| Phase | `lib/models/phase.dart` | assets JSON / API |
| Lesson | `lib/models/program.dart` | `loadLesson()` 按需加载 |
| Scene | `lib/models/scene.dart` | `loadLesson()` 按需加载 |
| Step | `lib/models/scene.dart` | `loadLesson()` 按需加载 |
| ClassTeaching | `lib/models/class_teaching.dart` | assets JSON / API |

数据服务：`lib/services/data_service.dart` 通过 `CourseDataService` 统一管理，assets / API 双数据源。

## 相关文档

- [architecture.md](architecture.md) — 分层结构与数据流
- [data-model.md](data-model.md) — 模型层级与 JSON 字段对照
- [workflow.md](workflow.md) — 从蓝图到落地：CLI 与 Studio 能力对照
- [testing.md](testing.md) — 单元测试与集成测试职责划分
- [specification/index.md](../../specification/index.md) — 领域架构与设计规则
- [specification/course/tree.md](../../specification/course/tree.md) — 课程树字段规格
- [specification/class/teaching.md](../../specification/class/teaching.md) — ClassTeaching 字段规格
- [ROADMAP.md](../../../ROADMAP.md) — 产品路线图
