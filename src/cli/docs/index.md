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

### 课时蓝图 — 从生产材料生成

```
qtcloud-course lesson blueprint --from <资料.md> --to <课时.json>
```

输出 Lesson → Scene 二级结构。每个场景是一个操作步骤，`type: step` 为正常路径，`type: exception` 为异常/失败分支。场景序列按操作流程排序。

### 课时设计 — 基于已有课时迭代修改

```
qtcloud-course lesson design --file <课时.json> --instruction "第一个scene改成demo" --to <输出.json>
```

## 配置

| 环境变量 | 默认值 | 用途 |
|----------|--------|------|
| `LLM_API_KEY` | — | LLM API Key |
| `LLM_BASE_URL` | `https://api.deepseek.com` | LLM 地址 |
| `LLM_MODEL` | `deepseek-v4-flash` | LLM 模型 |
