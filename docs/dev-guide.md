# 开发指南

量潮课程云的开发指引。

## 入门

1. 阅读 [specification/domain.md](../specification/domain.md) 了解领域架构
2. 阅读 [specification/data-model.md](../specification/data-model.md) 了解数据模型
3. 查看 [studio ROADMAP](../../src/studio/ROADMAP.md) 了解当前开发目标

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

- [specification/domain.md](../specification/domain.md) — 领域架构与设计规则
- [specification/data-model.md](../specification/data-model.md) — 数据模型与字段规格
- [ROADMAP.md](../../ROADMAP.md) — 产品路线图
