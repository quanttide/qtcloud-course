# lesson — 课时操作

Lesson → Scene 二级结构。每个场景是一个操作步骤，异常通过嵌套的 `exception` 字段表达。

内部两遍 LLM 调用：先切场景（提取）→ 再编排（排序+挂异常）。

## blueprint — 从生产材料生成

```
qtcloud-course lesson blueprint --from <资料.md> --to <课时.json>
```

### 内部流程

1. **切场景** — 从素材提取原始操作步骤（无序，无异常）
2. **编排** — 排序、挂异常分支

### 输出示例

```json
{
  "title": "发布",
  "description": "掌握版本发布流程",
  "scenes": [
    {
      "title": "更新版本号",
      "description": "修改配置文件中的版本字段"
    },
    {
      "title": "更新 CHANGELOG",
      "description": "添加变更记录",
      "exception": {
        "title": "缺 CHANGELOG 条目",
        "description": "以 git log 为源补写"
      }
    },
    {
      "title": "提交修改",
      "description": "git commit"
    },
    {
      "title": "打标签",
      "description": "git tag + git push",
      "exception": {
        "title": "Tag scope 前缀缺失",
        "description": "删除错误 tag 并重建"
      }
    }
  ]
}
```

### 场景顺序

场景序列按操作流程排序。每个正常场景可带一个 `exception` 嵌套对象，表示该步骤的异常/失败分支。异常不单独成场景，而是挂在父场景下。

## design — 基于已有课时迭代

```
qtcloud-course lesson design --file <课时.json> --instruction "增加一个验证步骤" --to <输出.json>
```

## preview — 渲染为 DAG HTML

```
qtcloud-course lesson preview --from <课时.json> --to <预览.html>
```

输出水平 DAG 图：场景卡片从左到右排列，异常分支以红色卡片挂载在父场景下方。不调用 LLM。
