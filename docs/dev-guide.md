# 开发指南

量潮课程云的领域架构、数据模型和设计原则。

---

## 领域架构

### 两个子领域

```
┌──────────────────────────────────────────────────────┐
│               课程单位子领域                           │
│   (课程研发：教什么、用什么教)                          │
│                                                       │
│   Program → Course → Phase → Lesson → Scene → Step    │
└──────────────────────────────────────────────────────┘
                            │ 引用/实施
                            ▼
┌──────────────────────────────────────────────────────┐
│               教学单位子领域                           │
│   (教学实施：谁来教、怎么教)                            │
│                                                       │
│   Class(班级)                                         │
└──────────────────────────────────────────────────────┘
```

### 课程单位子领域

关注课程研发，定义教学内容的结构：

| 实体 | 级别 | 职责 | 示例 |
|:----|:----|:----|:----|
| Program | 专业 | 顶层教学计划 | 大数据微专业 |
| Course | 课程 | 教学单元 | 数据工程 |
| Phase | 阶段 | 课程内的教学阶段 | 基础篇、进阶篇 |
| Lesson | 课时 | 教学内容的最小组织单元 | 安装编程环境 |
| Scene | 场景 | 课时内的教学场景 | 配置 DeepSeek |
| Step | 步骤 | 场景内的操作步骤 | 打开设置页面 |

上四级（Program → Lesson）负责**教学组织**，下两级（Scene → Step）负责**内容细节**。

### 教学单位子领域

关注教学实施，组织学员和教学资源：

| 实体 | 职责 | 示例 |
|:----|:----|:----|
| Class | 班级，学员共同学习的组织 | 浙理班级 |

### 关键关系

- **Program → Course → Phase → Lesson** 为嵌套包含关系，子级随父级加载
- **Lesson → Scene → Step** 为按需加载关系，通过 `loadLesson(lessonId)` 延迟加载
- **Class 引用 Program 或 Course** 的内容进行教学实施（通过 `refType` + `refId`），不重新定义教学内容
- **课程单位不感知教学单位**，Program/Course/Lesson 中不出现 Class 引用

### 设计规则

1. **课程单位定义内容，教学单位负责实施**——Class 不自主开发课程，直接使用 Program / Course 的产出
2. **课程域不引用组织域**——Class 不知道谁买单，Course 不知道谁在学习
3. **内容状态与教学状态分离**——`ContentStatus`（draft/published）控制研发流程，`ClassStatus`（preparing/active/ended）控制教学流程

---

## 数据模型

### 课程树：六级嵌套

```
Program
├── id, name, description, status, courses[]
├── Course
│   ├── id, name, description, status, sortOrder, phases[]
│   ├── Phase
│   │   ├── id, name, description, status, sortOrder, lessons[]
│   │   ├── Lesson
│   │   │   ├── id, title, description, duration, status, sortOrder, scenes[]
│   │   │   ├── Scene
│   │   │   │   ├── id, name, title, steps[], choices[], verifyTip, videoUrl
│   │   │   │   ├── Step (order, content)
│   │   │   │   └── Choice (label, targetSceneId)
```

嵌套结构而非 ID 引用，减少查询次数。Lesson 的 Scene/Step 通过 `loadLesson()` 按需加载，不随树一起展开。

### ClassTeaching

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | 是 | — | 唯一标识 |
| `name` | string | 是 | — | 班级名称 |
| `refName` | string | 是 | — | 引用的专业/课程名称（展示用） |
| `refType` | string | 否 | `"program"` | `"program"` / `"course"` |
| `refId` | string | 是 | — | 引用的 Program/Course ID |
| `status` | string | 否 | `"preparing"` | `"preparing"` / `"active"` / `"ended"` |
| `startDate` | string | 是 | — | ISO 日期 |
| `endDate` | string | 是 | — | ISO 日期 |
| `studentCount` | number | 否 | `0` | 学员数 |
| `progress` | number | 否 | `0.0` | 0.0 ~ 1.0 |

#### ClassStatus

| 值 | 含义 |
|---|---|
| `"preparing"` | 筹备中，可调整教学计划 |
| `"active"` | 进行中，教学计划锁定仅可微调 |
| `"ended"` | 已结束，学员成绩冻结 |

#### RefType

| 值 | 含义 |
|---|---|
| `"program"` | 引用整个专业作为教学内容 |
| `"course"` | 引用单个课程作为教学内容 |

---

## 不解决的问题

- **教学质量管理**：评分、反馈、作业批改——属于教学评估领域
- **排课与资源调度**：教室、设备、时间冲突检测——独立排课模块
- **AI 辅助教学**：内容生成、智能批改——作为独立能力层引入

---

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
