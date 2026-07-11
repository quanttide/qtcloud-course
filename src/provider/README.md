# qtcloud-course-provider

量潮课程云服务端。提供课程研发与教学管理的 RESTful API。

## 快速开始

```bash
go run ./cmd/server
```

服务默认监听 `:8080`，可通过 `LISTEN_ADDR` 环境变量覆盖：

```bash
LISTEN_ADDR=:9090 go run ./cmd/server
```

## API

所有资源均支持标准 CRUD。

### Program（专业）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/programs` | 列出所有专业 |
| POST | `/programs` | 创建专业 |
| GET | `/programs/{id}` | 获取专业 |
| PUT | `/programs/{id}` | 更新专业 |
| DELETE | `/programs/{id}` | 删除专业 |

### Course（课程）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/courses` | 列出所有课程 |
| POST | `/courses` | 创建课程 |
| GET | `/courses/{id}` | 获取课程 |
| PUT | `/courses/{id}` | 更新课程 |
| DELETE | `/courses/{id}` | 删除课程 |

### Lesson（课时）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/lessons` | 列出所有课时 |
| POST | `/lessons` | 创建课时 |
| GET | `/lessons/{id}` | 获取课时 |
| PUT | `/lessons/{id}` | 更新课时 |
| DELETE | `/lessons/{id}` | 删除课时 |

### Scene（视频片段）

互动课时的分支视频场景，按 `lessonId` 归属。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/scenes?lessonId={id}` | 列出课时的所有场景 |
| POST | `/scenes` | 创建场景 |
| GET | `/scenes/{id}` | 获取场景 |
| PUT | `/scenes/{id}` | 更新场景 |
| DELETE | `/scenes/{id}` | 删除场景 |

### Class（班级）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/classes` | 列出所有班级 |
| POST | `/classes` | 创建班级 |
| GET | `/classes/{id}` | 获取班级 |
| PUT | `/classes/{id}` | 更新班级 |
| DELETE | `/classes/{id}` | 删除班级 |

### 健康检查

| 方法 | 路径 |
|------|------|
| GET | `/healthz` |

## 数据模型

Program、Course、Lesson 均为**独立资源**，通过 ID 列表互相引用：

```
Program.courseIds → Course
Course.lessonIds  → Lesson
```

Class 引用 Program 或 Course 的内容进行教学（`refType` + `refId`）。

### Lesson 互动结构

Lesson 通过 Scene 构建分支视频体验：

```json
{
  "id": "less-1",
  "title": "Git 入门",
  "startSceneId": "scene-1",
  "scenes": [
    {
      "id": "scene-1",
      "videoUrl": "intro.mp4",
      "choices": [
        { "label": "继续", "targetSceneId": "scene-2" },
        { "label": "跳过", "targetSceneId": "scene-3" }
      ]
    }
  ]
}
```

## 技术栈

- Go 1.22+
- 纯标准库 `net/http`（增强 ServeMux），无外部依赖
- 当前使用内存存储，重启后数据丢失

## 测试

```bash
go test ./... -count=1 -cover
```
