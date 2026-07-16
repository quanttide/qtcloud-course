# qtcloud-course CLI

> 从 Markdown 原始资料生成结构化课程蓝图。

## 命令分层

| 层级 | 命令 | 说明 |
|------|------|------|
| 课程 | `course` | Program → Course → Phase → Lesson |
| 课时 | `lesson` | Lesson → Scene（含异常嵌套） |
| 场景 | `scene` | Scene → Steps（顺序，不分支） |

每个层级三个子命令：

| 子命令 | 功能 |
|--------|------|
| `blueprint` | 从 Markdown 原始资料生成 |
| `design` | 基于已有 JSON + 人类指示迭代修改 |
| `preview` | 将 JSON 渲染为 HTML（不调用 LLM） |

## 文档

- [course.md](course.md) — 课程蓝图、设计、预览
- [lesson.md](lesson.md) — 课时蓝图（两遍 LLM）、设计、预览
- [scene.md](scene.md) — 场景蓝图、设计、预览

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
