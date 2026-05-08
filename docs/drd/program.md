# ProgramData Schema

## Fixture 路径

`assets/fixtures/programs.json`

## 概述

Program（专业）→ Course（课程）→ Lesson（课时）三级树形结构，描述课程单位子领域的内容组织。

## ProgramData

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | 是 | 唯一标识 |
| `name` | string | 是 | 专业名称 |
| `description` | string | 否 | 专业描述 |
| `status` | string | 否 | `"draft"` / `"published"` |
| `courses` | object[] | 是 | 包含的课程列表 |

### ContentStatus 枚举

| 值 | 含义 |
|---|---|
| `"draft"` | 草稿，研发中 |
| `"published"` | 已发布，可供教学引用 |

## CourseData

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | 是 | — | 唯一标识 |
| `name` | string | 是 | — | 课程名称 |
| `description` | string | 否 | `""` | 课程描述 |
| `status` | string | 否 | `"draft"` | `"draft"` / `"published"` |
| `lessons` | object[] | 是 | `[]` | 包含的课时列表 |

## LessonData

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | 是 | — | 唯一标识 |
| `title` | string | 是 | — | 课时标题 |
| `description` | string | 否 | `""` | 课时描述 |
| `duration` | number | 否 | `45` | 课时时长（分钟） |
| `status` | string | 否 | `"draft"` | `"draft"` / `"published"` |

## 数据关系

```
Program (1) ──包含──> Course (N) ──包含──> Lesson (N)
```

- 一个 Program 包含多个 Course
- 一个 Course 包含多个 Lesson
- 删除 Program 级联删除其 Course 和 Lesson
- Lesson 不独立存在，必须归属某个 Course
