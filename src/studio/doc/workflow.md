# 工作流：从蓝图到落地

## 概述

课程制作分两条路径，最终在 Provider 数据层汇合：

```
┌──────────────────────┐     ┌──────────────────────┐
│        CLI           │     │       Studio         │
│   qtcloud-course     │     │   Flutter 桌面端       │
│   面向 AI            │     │   面向人类             │
│                      │     │                      │
│  blueprint 生成     │     │  课程编排树编辑        │
│  → 批量产出课程JSON  │     │  → 手动创建/调整      │
│  → 适用于大规模导入   │     │  → 适用于精细微调     │
└────────┬─────────────┘     └──────────┬───────────┘
         │                              │
         ▼                              ▼
    ┌────────────────────────────────────────┐
    │              Provider (Go)              │
    │   REST API :8080                        │
    │   种子数据导入 / 运行时 CRUD             │
    └────────────────────────────────────────┘
```

- **CLI 路径**：AI 生成课程蓝图 JSON → Provider 种子导入 → Studio 可浏览/调整/发布
- **Studio 路径**：人类在图形界面中直接编排 → Provider API 读写

两条路径产出的数据格式一致，可互操作。

## 课程编排树

Studio 课程研发板块的核心是 **Program → Course → Phase → Lesson → Scene → Step** 六级树：

| 层级 | 含义 | 人类入口（Studio） | AI 入口（CLI） |
|------|------|-------------------|----------------|
| Program | 专业，顶层教学计划 | 浏览 → 新建 → 编辑 | `blueprint` 顶层 |
| Course | 课程，教学单元 | 浏览 → 新建 → 编辑 | `blueprint` 课程节点 |
| Phase | 阶段，课程内部分期 | 浏览 → 新建 → 编辑 | `blueprint` 阶段节点 |
| Lesson | 课时，最小内容组织单元 | 浏览 → 新建 → 编辑 | `blueprint` 课时节点 |
| Scene | 场景，课时的分支视频片段 | 浏览 → 试听预览 | `blueprint` 场景节点 |
| Step | 步骤，场景内的操作引导 | 浏览 | `blueprint` 步骤节点 |

### 当前状态

| 功能 | Studio 支持情况 | CLI 支持情况 |
|------|----------------|-------------|
| 浏览六级树 | ✅ 展开/折叠 | — |
| 状态标记（草稿/已发布） | ✅ StatusChip | — |
| 试听预览 | ✅ PreviewScreen（Scene→Step 逐步骤） | — |
| 新建层级节点 | ❌ | ✅ `blueprint` 生成 |
| 编辑层级节点 | ❌ | ✅ `blueprint` 生成 |
| 删除层级节点 | ❌ | — |
| 拖拽排序 | ❌ | — |
| 发布（草稿→已发布） | ❌ | — |
| 从蓝图导入 | ❌ | ✅ 输出兼容格式 |

## 蓝图规格

CLI `blueprint` 命令产出的 JSON 与 Studio 数据模型完全兼容。

### 最小示例

```json
{
  "programs": [
    {
      "id": "prog-1",
      "name": "AI 编程入门",
      "description": "面向零基础学员的 AI 编程课程",
      "status": "draft",
      "courses": [
        {
          "id": "course-1",
          "name": "Python 基础",
          "description": "Python 基础语法与工具链",
          "status": "draft",
          "phases": [
            {
              "id": "phase-1",
              "name": "环境搭建",
              "sortOrder": 1,
              "lessons": [
                {
                  "id": "lesson-1",
                  "title": "开发环境搭建",
                  "description": "安装 Python 和 IDE",
                  "duration": 30,
                  "status": "draft",
                  "sortOrder": 1,
                  "scenes": [
                    {
                      "id": "scene-1",
                      "name": "python-install",
                      "title": "安装 Python",
                      "steps": [
                        { "order": 1, "content": "访问 python.org 下载" },
                        { "order": 2, "content": "运行安装程序" }
                      ],
                      "choices": [
                        { "label": "继续", "targetSceneId": "scene-2" }
                      ],
                      "verifyTip": "终端输入 python --version 确认",
                      "videoUrl": ""
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### CLI 到 Studio 的导入流程

```
CLI blueprint 生成 → seed.json → Provider 种子数据
                                    ↓
                              Studio 启动
                                    ↓
                          assets 模式或 API 模式
                                    ↓
                          课程树展示在 ProgramScreen
```

## 从蓝图到落地：完整流程

### 路径 A：AI 先导（CLI → Provider → Studio）

```
1. 需求分析 (人类)
   ↓
2. CLI blueprint 生成课程大纲 (AI)
   ↓
3. 大纲 JSON 导入 Provider 种子数据
   ↓
4. Studio 启动，课程树展示完整结构
   ↓
5. 人类在 Studio 中审阅 → 调整 → 填充内容 → 发布
```

此路径适用于：新专业批量创建、课程体系重构、从旧系统迁移。

### 路径 B：Studio 原生（人类直接操作）

```
1. Studio 中新建 Program
   ↓
2. 逐级创建 Course → Phase → Lesson
   ↓
3. 在 Lesson 中编排 Scene → Step
   ↓
4. 预览验证
   ↓
5. 发布
```

此路径适用于：单个课程创建、已有课程微调、课时内容编辑。

## 数据一致性规则

- CLI 产出的 JSON 可直接作为 Provider 种子数据，Studio 无需二次转换
- Studio 编辑后的数据可通过 Provider API 导出，与 CLI 蓝图格式互通
- 所有层级节点的 status 统一使用 `draft` / `published` 俩状态
- 层级间通过嵌套结构（而非独立 ID 引用）组织，一个 JSON 文件包含完整树
