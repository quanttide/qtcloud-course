# scene — 场景操作

Scene → Steps 二级结构。场景内的步骤按顺序执行，不分支。

## blueprint — 从生产材料生成

```
qtcloud-course scene blueprint --from <资料.md> --to <场景.json>
```

将场景拆解为 3-6 个按顺序执行的子步骤。

### 输出示例

```json
{
  "title": "更新版本号",
  "description": "手动修改配置文件中的版本字段",
  "steps": [
    {
      "title": "定位配置文件",
      "description": "找到 pyproject.toml 中的 version 字段"
    },
    {
      "title": "按 SemVer 递增",
      "description": "根据变更类型递增主版本号/次版本号/修订号"
    },
    {
      "title": "检查 tag 冲突",
      "description": "确认新版本号不与已有标签重复"
    },
    {
      "title": "保存并验证",
      "description": "保存文件，运行版本校验脚本确认"
    }
  ]
}
```

## design — 基于已有场景迭代

```
qtcloud-course scene design --file <场景.json> --instruction "增加一个验证步骤" --to <输出.json>
```

## preview — 渲染为 HTML

```
qtcloud-course scene preview --from <场景.json> --to <预览.html>
```

输出步骤卡片视图，不调用 LLM。
