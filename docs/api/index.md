# API 文档

所有资源均支持标准 CRUD。

## Program（专业）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/programs` | 列出所有专业 |
| POST | `/programs` | 创建专业 |
| GET | `/programs/{id}` | 获取专业 |
| PUT | `/programs/{id}` | 更新专业 |
| DELETE | `/programs/{id}` | 删除专业 |

## Course（课程）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/courses` | 列出所有课程 |
| POST | `/courses` | 创建课程 |
| GET | `/courses/{id}` | 获取课程 |
| PUT | `/courses/{id}` | 更新课程 |
| DELETE | `/courses/{id}` | 删除课程 |

## Lesson（课时）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/lessons` | 列出所有课时 |
| POST | `/lessons` | 创建课时 |
| GET | `/lessons/{id}` | 获取课时 |
| PUT | `/lessons/{id}` | 更新课时 |
| DELETE | `/lessons/{id}` | 删除课时 |

## Scene（视频片段）

互动课时的分支视频场景，按 `lessonId` 归属。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/scenes?lessonId={id}` | 列出课时的所有场景 |
| POST | `/scenes` | 创建场景 |
| GET | `/scenes/{id}` | 获取场景 |
| PUT | `/scenes/{id}` | 更新场景 |
| DELETE | `/scenes/{id}` | 删除场景 |

## Class（班级）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/classes` | 列出所有班级 |
| POST | `/classes` | 创建班级 |
| GET | `/classes/{id}` | 获取班级 |
| PUT | `/classes/{id}` | 更新班级 |
| DELETE | `/classes/{id}` | 删除班级 |

## 健康检查

| 方法 | 路径 |
|------|------|
| GET | `/healthz` |

## 数据模型关系

Program、Course、Phase、Lesson 均为**独立资源**，通过 ID 列表互相引用：

```
Program.courseIds → Course
Course           → Phase (courseId)
Phase.lessonIds  → Lesson
Lesson           → Scene (lessonId)
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
      "videoUrl": "less-1/intro.mp4",
      "choices": [
        { "label": "继续", "targetSceneId": "scene-2" },
        { "label": "跳过", "targetSceneId": "scene-3" }
      ]
    }
  ]
}
```

## 视频存储

视频文件存放在本地磁盘 `./data/video/` 目录，通过 `/video/{path}` 访问：

```
GET /video/less-1/intro.mp4    # 返回 ./data/video/less-1/intro.mp4
```

`Scene.videoUrl` 存的是相对于 `./data/video/` 的路径。
目录路径可通过 `VIDEO_DIR` 环境变量覆盖：

```bash
VIDEO_DIR=/mnt/videos go run ./cmd/server
```
