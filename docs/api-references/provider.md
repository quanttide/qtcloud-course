# Provider API 参考

qtcloud-course provider 的 HTTP 接口清单。单一路由面的内容资源接口：服务端只出内容实体，不做前端视图适配——展示层组装（目录卡片、播放器 segments 等）属应用侧职责（见 qtclass `src/provider`）。

实现位于 `src/provider`，路由组装见 `cmd/server/main.go`。

## 通用约定

- 请求与响应均为 JSON；创建成功返回 201，删除成功返回 204；
- 错误响应统一为 `{"error":"..."}`，状态码含义：400 参数非法、404 资源不存在、409 名称冲突；
- 存储经 `QTCLOUD_COURSE_STORE` 选择：`memory`（默认，测试用）或 `oss`（生产，每表一个对象）；
- 各实体的 `slug` 由服务端在创建时依据名称自动生成，无需传入；
- 名称唯一性约束：Course 的 `name`、Lesson 的 `title`、Criterion 的 `title` 均全局唯一，重复创建返回 409。

## Course 课程

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/courses` | 全部课程实体，按 `sortOrder` 排序 |
| GET | `/courses/{id}` | 单课详情 |
| POST | `/courses` | 创建 |
| PUT | `/courses/{id}` | 更新 |
| DELETE | `/courses/{id}` | 删除 |

```json
{ "name": "生产实习", "description": "走进真实业务", "status": "published", "sortOrder": 5 }
```

## Lesson 课时

课程的子资源；`sortOrder` 保证课时顺序。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/lessons` | 全部课时 |
| POST | `/lessons` | 创建（courseId 由请求体指定） |
| GET | `/lessons/{id}` | 详情 |
| PUT | `/lessons/{id}` | 更新 |
| DELETE | `/lessons/{id}` | 删除 |
| GET | `/courses/{courseId}/lessons` | 列出指定课程的课时 |
| POST | `/courses/{courseId}/lessons` | 在指定课程下创建 |

```json
{
  "title": "创立故事",
  "description": "...",
  "duration": 10,
  "status": "published",
  "startSceneId": "scen-1",
  "criteria": ["cri-1"]
}
```

`criteria` 引用本课时的 Criterion ID；课时总验收 = 场景全过加跨场景约束。

## Scene 场景

课时的子资源。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/scenes/{id}` | 详情 |
| PUT | `/scenes/{id}` | 更新 |
| DELETE | `/scenes/{id}` | 删除 |
| GET | `/lessons/{lessonId}/scenes` | 列出指定课时的场景 |
| POST | `/lessons/{lessonId}/scenes` | 在指定课时下创建 |

```json
{
  "title": "场景一",
  "videoUrl": "https://cdn.example.com/intro.mp4",
  "verifyTip": "确认 Zed 已启动",
  "steps": [ { "order": 1, "content": "打开终端" } ],
  "choices": [ { "label": "继续", "targetSceneId": "scen-2" } ],
  "criteria": ["cri-1"]
}
```

## Criterion 验收标准

课程研发阶段定义的原子验收单元，跨领域对接源（学习云注册时快照归档）。两级挂载：课时级（总验收）与场景级（每步判定）；唯一性由服务端 ID 保证，全局清单供快照注册管道拉取。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/criteria` | 全局清单（快照注册管道的数据源） |
| GET | `/criteria/{id}` | 详情 |
| PUT | `/criteria/{id}` | 更新 |
| DELETE | `/criteria/{id}` | 删除 |
| GET | `/lessons/{lessonId}/criteria` | 列出指定课时的标准（含其下场景的） |
| POST | `/lessons/{lessonId}/criteria` | 创建课时级标准 |
| GET | `/scenes/{sceneId}/criteria` | 列出指定场景的标准 |
| POST | `/scenes/{sceneId}/criteria` | 创建场景级标准（自动回填所属课时） |

```json
{ "title": "会连接 Zed", "description": "Zed 已启动且主题配置生效" }
```

## 辅助接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/healthz` | 健康检查 |
