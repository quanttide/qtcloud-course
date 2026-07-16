# qtcloud-course CLI

> 从 Markdown 原始资料生成结构化课程蓝图。

## 命令

### 课程蓝图（Program → Course → Phase → Lesson）

```
qtcloud-course course blueprint --from <input.md> --to <output.json>
```

主题从文件名推断。输出不含 Scene 层级，Scene 级设计由 `lesson blueprint` 负责。

### 课时蓝图（Lesson → Scene）

```
qtcloud-course lesson blueprint --from <input.md> --to <output.json>
```

为单个课时设计完整的场景编排（lecture/demo/exercise/discussion/quiz/review）。

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
