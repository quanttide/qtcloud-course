# course — 课程操作

Program → Course → Phase → Lesson 四级结构，不含 Scene。

## blueprint — 从生产材料生成

```
qtcloud-course course blueprint --from <资料.md> --to <蓝图.json>
```

主题从文件名推断。输出 JSON 示例：

```json
{
  "title": "DevOps 实践",
  "description": "从真实生产中学 DevOps",
  "courses": [
    {
      "title": "发布管理",
      "description": "版本发布流程",
      "phases": [
        {
          "title": "理解发布",
          "description": "小步快跑理念",
          "lessons": [
            { "title": "发布流程", "description": "从版本号到 Release" }
          ]
        }
      ]
    }
  ]
}
```

## design — 基于已有蓝图迭代

```
qtcloud-course course design --file <蓝图.json> --instruction "把第一阶段改成3节课" --to <输出.json>
```

读取已有 JSON，结合人类指示输出修改后的版本。只改指示部分，其余不变。

## preview — 渲染为 HTML

```
qtcloud-course course preview --from <蓝图.json> --to <预览.html>
```

输出层级结构视图（课程→阶段→课时），不调用 LLM。
