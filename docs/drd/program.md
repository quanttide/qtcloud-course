# ProgramData Schema

## Fixture 路径

`assets/fixtures/programs.json`

## 概述

Program（专业）、Course（课程）、Lesson（课时）三者均为**独立资源**，通过 ID 列表相互引用，描述课程单位子领域的内容组织。

## ProgramData

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | 是 | — | 唯一标识 |
| `name` | string | 是 | — | 专业名称 |
| `description` | string | 否 | `""` | 专业描述 |
| `status` | string | 否 | `"draft"` | `"draft"` / `"published"` |
| `courseIds` | string[] | 否 | `[]` | 引用的课程 ID 列表 |

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
| `lessonIds` | string[] | 否 | `[]` | 引用的课时 ID 列表 |

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
Program ──引用──> Course ──引用──> Lesson
```

- Program 通过 `courseIds` 引用多个 Course
- Course 通过 `lessonIds` 引用多个 Lesson
- 三者均为**独立资源**，各自拥有独立生命周期
- 删除 Program **不**级联删除其引用的 Course
- 删除 Course **不**级联删除其引用的 Lesson
- 一个 Course 可被多个 Program 引用
- 一个 Lesson 可被多个 Course 引用
- Lesson 独立存在，不强制归属某个 Course
