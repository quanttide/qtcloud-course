# 数据模型

层级：Program → Course → Phase → Lesson → Scene → Step

## JSON 字段对照

### Program

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| name | String | 专业名称 |
| description | String | 描述 |
| status | String | draft / published |
| courses | List\<Course\> | 课程列表 |

### Course

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| name | String | 课程名称 |
| description | String | 描述 |
| status | String | draft / published |
| phases | List\<Phase\> | 阶段列表 |

### Phase

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| name | String | 阶段名称 |
| sortOrder | int | 排序序号 |
| lessons | List\<Lesson\> | 课时列表 |

### Lesson

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| title | String | 课时标题 |
| description | String | 描述 |
| duration | int | 时长（分钟） |
| status | String | draft / published |
| sortOrder | int | 排序序号 |
| scenes | List\<Scene\> | 场景列表（按需加载） |

### Scene

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 唯一标识 |
| name | String | 场景标识名 |
| title | String | 场景标题 |
| steps | List\<Step\> | 步骤列表 |
| choices | List\<Choice\> | 分支选项 |
| verifyTip | String | 验证提示 |

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
