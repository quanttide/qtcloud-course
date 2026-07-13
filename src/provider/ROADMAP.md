# ROADMAP — v0.0.3

## 目标

以 **Step 模型**为核心，完成从"视频片段"到"可交互操作指南"的升级。

## 背景

当前 Scene 支持视频播放 + 场景间跳转（Choices），已能满足线性视频学习。但实际教学场景中，学员需要跟着视频一步一步操作，并在遇到问题时获得指引——这需要 Step 模型具备异常分支能力。

## 任务

### 1. Step 模型扩展

- [ ] `Step` 增加 `errorSteps` 字段，在当前步骤内嵌入异常处理子步骤
- [ ] `Step` 增加可选的图片/代码块等辅助资源字段（`imageUrl` / `codeBlock`）

```go
type Step struct {
    Order      int     `json:"order"`
    Content    string  `json:"content"`
    ImageURL   string  `json:"imageUrl,omitempty"`   // 辅助截图
    CodeBlock  string  `json:"codeBlock,omitempty"`  // 示例代码
    ErrorSteps []Step  `json:"errorSteps,omitempty"` // 异常子步骤
}
```


### 2. 路由重组：资源嵌套

将独立资源路径改为按父级嵌套，与数据模型的层级关系对齐。

#### Scenes 嵌套到 Lessons

```
# 当前                              # 改为
GET    /scenes?lessonId={id}        GET    /lessons/{id}/scenes
POST   /scenes                      POST   /lessons/{id}/scenes
GET    /scenes/{id}                 GET    /lessons/{id}/scenes/{sceneId}
PUT    /scenes/{id}                 PUT    /lessons/{id}/scenes/{sceneId}
DELETE /scenes/{id}                 DELETE /lessons/{id}/scenes/{sceneId}
```

- [ ] Scene handler 改为从 URL path 读取 lessonId，不再依赖查询参数
- [ ] POST 自动从路径推断 lessonId，请求体不再需要传 `lessonId`

#### Phases 嵌套到 Courses

```
# 当前                              # 改为
GET    /phases?courseId={id}        GET    /courses/{id}/phases
POST   /phases                      POST   /courses/{id}/phases
GET    /phases/{id}                 GET    /courses/{id}/phases/{phaseId}
PUT    /phases/{id}                 PUT    /courses/{id}/phases/{phaseId}
DELETE /phases/{id}                 DELETE /courses/{id}/phases/{phaseId}
```

- [ ] Phase handler 改为从 URL path 读取 courseId
- [ ] 嵌套后所有 Scene/Phase 操作都带有父级上下文，URL 即表达资源归属关系

### 3. Step 渲染 API

- [ ] 新增 `GET /lessons/{id}/scenes/{sceneId}/steps` 端点，按序返回场景的操作步骤
- [ ] 每个 Step 携带 `depth` 属性，前端可据此渲染缩进层级（正常步骤 depth=0，异常子步骤 depth=1）

### 4. 视频-步骤时间锚点

- [ ] `Step` 增加 `timestamp` 字段（秒），标记该步骤在视频中对应的起止时间

```go
type Step struct {
    // 现有字段...
    TimestampStart int `json:"timestampStart,omitempty"` // 起始秒数
    TimestampEnd   int `json:"timestampEnd,omitempty"`   // 结束秒数
}
```

- [ ] 前端可根据时间锚点实现"视频跳到对应位置时高亮当前步骤"

### 5. 数据加载

- [ ] `data/profile/` 中的 lesson JSON 支持带 Steps 的完整场景数据导入
- [ ] 启动时通过环境变量 `DATA_DIR` 加载 JSON 种子数据，替代 fixture 硬编码


### 7. 统一 name/title 字段

#### 补齐缺失字段

| 资源 | 当前有 | 需补齐 |
|------|--------|--------|
| Program | `name`（显示名） | `title`（显示名副本） |
| Course | `name`（显示名） | `title`（显示名副本） |
| Phase | `name`（显示名） | `title`（显示名副本） |
| Lesson | `title`（显示名） | `name`（URL slug） |
| Scene | `title`（显示名） | `name`（URL slug） |
| Class | `name`（显示名） | `title`（显示名副本） |

- [ ] Lesson/Scene 增加 `name` 字段（URL 友好的 slug，如 `"zed-install"`）
- [ ] Program/Course/Phase/Class 增加 `title` 字段（显示名，初始化时与 `name` 相同）
- [ ] 所有资源的 `name` 在 Create 时自动从 `title` 生成 slug，也可手动指定
- [ ] Store 增加 `GetByName(name)` 方法
- [ ] Handler 增加 `GET /{resource}/name/{name}` 端点，按 name 查询

### 8. 自动化测试补充

- [ ] name 重复校验测试

- [ ] Step 序列化/反序列化测试
- [ ] API `/lessons/{id}/scenes/{sceneId}/steps` 集成测试
- [ ] 含异常分支的 Step JSON 校验测试

## 交付标准

- `go test ./... -count=1` 全部通过
- `vibe-coding/lesson1.json` 中的 4 个场景均包含完整的 Steps + 时间锚点
- 至少一个场景的某个 Step 包含 errorSteps 异常分支数据
