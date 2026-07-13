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

### 2. Step 渲染 API

- [ ] 新增 `GET /scenes/:id/steps` 端点，按序返回场景的操作步骤
- [ ] 每个 Step 携带 `depth` 属性，前端可据此渲染缩进层级（正常步骤 depth=0，异常子步骤 depth=1）

### 3. 视频-步骤时间锚点

- [ ] `Step` 增加 `timestamp` 字段（秒），标记该步骤在视频中对应的起止时间

```go
type Step struct {
    // 现有字段...
    TimestampStart int `json:"timestampStart,omitempty"` // 起始秒数
    TimestampEnd   int `json:"timestampEnd,omitempty"`   // 结束秒数
}
```

- [ ] 前端可根据时间锚点实现"视频跳到对应位置时高亮当前步骤"

### 4. 数据加载

- [ ] `data/profile/` 中的 lesson JSON 支持带 Steps 的完整场景数据导入
- [ ] 启动时通过环境变量 `DATA_DIR` 加载 JSON 种子数据，替代 fixture 硬编码

### 5. 自动化测试

- [ ] Step 序列化/反序列化测试
- [ ] API `/scenes/:id/steps` 集成测试
- [ ] 含异常分支的 Step JSON 校验测试

## 交付标准

- `go test ./... -count=1` 全部通过
- `vibe-coding/lesson1.json` 中的 4 个场景均包含完整的 Steps + 时间锚点
- 至少一个场景的某个 Step 包含 errorSteps 异常分支数据
