# qtcloud-course CLI

> 课程蓝图生成工具。从主题/原始资料生成 Program → Course → Phase → Lesson → Scene 五层课程结构，支持导入 Studio。

## 用途

| 命令 | 能力 | 输出 |
|------|------|------|
| `course` | 给定主题+原始资料，LLM 生成课程蓝图 | Markdown 文本 / 结构化 JSON |
| `validate` | 校验课程 JSON 数据结构完整性 | 校验报告 |
| `import` | 将课程 JSON 导入 Provider API | — |
| `export` | 从 Provider API 导出课程数据 | JSON |

## 当前局限

- 一次只生成 **一份** 蓝图，不支持批量或多版本
- 输入为单一文件，不支持多源合并
- 提示词固定，未区分"教工具"与"教概念"的教学目标
- `--format` 输出的 JSON 格式与 Studio `assets/programs.json` **不一致**，不能直接作为本地 JSON 加载
  - CLI 输出：`{ title, description, courses: [...] }`
  - Studio 加载：`[{ id, name, courses: [...] }]`
- `import` 命令的 Provider API 端点与 Provider 当前路由未对齐

## 架构

```
用户输入（主题 + 原始资料）
        │
        ▼
   course.rs ──→ LLM 生成
        │
        ▼
   types.rs 校验 ──→ JSON/Markdown
        │
        ▼
   provider.rs ──→ Provider API
```

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `QTCLOUD_API_BASE_URL` | `http://localhost:8080` | Provider 地址 |
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
