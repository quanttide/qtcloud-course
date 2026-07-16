# qtcloud-course CLI

> 从 Markdown 原始资料生成结构化课程蓝图 JSON。

## 用法

```
qtcloud-course course blueprint --from <input.md> --to <output.json>
```

| 参数 | 说明 |
|------|------|
| `--from` | 原始资料 Markdown 文件（主题从文件名推断） |
| `--to` | 输出课程蓝图 JSON 文件 |

## 输出

Program → Course → Phase → Lesson → Scene 五层结构，兼容 Studio 导入。

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
