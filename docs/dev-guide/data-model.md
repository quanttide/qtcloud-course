# 数据模型

层级：Course → Lesson → Scene → Step（三级课程树，Criterion 挂载在课时或场景上）

> 注：Provider API 已裁剪为 Course / Lesson / Scene / Criterion 四资源。Studio 本地模型中的 Program / Phase 仅用于旧数据兼容，服务端不再提供。

## JSON 字段对照

### Course

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| name | String | 课程名称 |
| slug | String | 语义标识（创建时按名称自动生成） |
| description | String | 描述 |
| status | String | draft / published |
| sortOrder | int | 排序序号（目录阶梯顺序） |

### Lesson

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| courseId | String | 所属课程 |
| title | String | 课时标题 |
| slug | String | 语义标识（创建时按名称自动生成） |
| description | String | 描述 |
| duration | int | 时长（分钟） |
| status | String | draft / published |
| sortOrder | int | 排序序号（课时顺序） |
| startSceneId | String | 入口场景 ID |
| criteria | List\<String\> | 引用的课时总验收标准（场景全过 + 跨场景约束——与场景级同构） |

### Scene

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| lessonId | String | 所属课时 |
| title | String | 场景标题 |
| slug | String | 语义标识（创建时按名称自动生成） |
| steps | List\<Step\> | 步骤列表 |
| choices | List\<Choice\> | 分支选项 |
| verifyTip | String | 验证提示 |
| criteria | List\<String\> | 引用的本场景完成判定标准（与课时级同构；场景级验收在每步发生） |

### Criterion

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识，学习云同源直连 |
| lessonId | String | 所属课时 |
| sceneId | String | 所属场景（场景级验收标准；空表示课时级） |
| title | String | 标准名称（人类可读，用于展示与检索） |
| description | String | 判定规则（什么算做对）；注册学习云时快照归档 |

### Step

| 字段 | 类型 | 说明 |
|------|------|------|
| order | int | 步骤序号 |
| content | String | 步骤内容 |

### Choice

| 字段 | 类型 | 说明 |
|------|------|------|
| label | String | 选项标签 |
| targetSceneId | String | 跳转场景 ID |
