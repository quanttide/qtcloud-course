# qtcloud-course CLI

> 从 Markdown 原始资料生成结构化课程蓝图。

## 命令

### 课程蓝图 — 从生产材料生成

```
qtcloud-course course blueprint --from <资料.md> --to <蓝图.json>
```

主题从文件名推断。输出 Program → Course → Phase → Lesson 四级结构，不含 Scene。

### 课程设计 — 基于已有蓝图迭代修改

```
qtcloud-course course design --file <蓝图.json> --instruction "把第一阶段改成3节课" --to <输出.json>
```

读取已有课程蓝图 JSON，结合人类设计指示输出修改后的版本。

### 课时蓝图 — 从生产材料生成（两遍 LLM 调用）

```
qtcloud-course lesson blueprint --from <资料.md> --to <课时.json>
```

内部流程：
1. **切场景** — 从素材提取原始操作步骤（无序，无异常）
2. **编排** — 按流程排序，异常通过 `exception` 字段嵌套表达

输出示例：
```json
{
  "title": "发布",
  "description": "教学目标",
  "duration_minutes": 45,
  "scenes": [
    {
      "title": "更新版本号",
      "description": "修改配置文件",
      "duration_minutes": 5
    },
    {
      "title": "更新CHANGELOG",
      "description": "添加变更记录",
      "duration_minutes": 5,
      "exception": {
        "title": "缺CHANGELOG条目",
        "description": "以git log为源补写",
        "duration_minutes": 10
      }
    }
  ]
}
```

### 课时设计 — 基于已有课时迭代修改

```
qtcloud-course lesson design --file <课时.json> --instruction "第一个场景改成demo" --to <输出.json>
```

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
