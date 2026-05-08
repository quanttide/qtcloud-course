# ClassTeachingData Schema

## Fixture 路径

`assets/fixtures/classes.json`

## 概述

Class（班级）描述教学单位子领域的组织实施。Class 引用课程单位的内容进行教学，不重新定义教学内容。

## ClassTeachingData

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | 是 | — | 唯一标识 |
| `name` | string | 是 | — | 班级名称 |
| `refName` | string | 是 | — | 引用的专业/课程名称（展示用） |
| `refType` | string | 否 | `"program"` | 引用类型：`"program"` / `"course"` |
| `refId` | string | 是 | — | 引用的 Program/Course ID |
| `status` | string | 否 | `"preparing"` | `"preparing"` / `"active"` / `"ended"` |
| `startDate` | string | 是 | — | 教学开始日期（ISO 日期） |
| `endDate` | string | 是 | — | 教学结束日期（ISO 日期） |
| `studentCount` | number | 否 | `0` | 学员数 |
| `progress` | number | 否 | `0.0` | 教学进度（0.0 ~ 1.0） |

### ClassStatus 枚举

| 值 | 含义 |
|---|---|
| `"preparing"` | 筹备中，可调整教学计划 |
| `"active"` | 进行中，教学计划锁定仅可微调 |
| `"ended"` | 已结束，学员成绩冻结 |

### RefType 枚举

| 值 | 含义 |
|---|---|
| `"program"` | 引用整个专业作为教学内容 |
| `"course"` | 引用单个课程作为教学内容 |

## 数据关系

```
Class ──引用──> Program | Course
```

- Class 引用 Program/Course 的内容，不包含 Lesson 副本
- 课程单位侧内容更新后，Class 侧可选择性同步
- 一个 Program/Course 可被多个 Class 引用
- Class 不感知组织侧信息（谁买单、谁学习）
