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

## Studio 功能需求

### 当前能力

| 功能 | 状态 | 说明 |
|------|------|------|
| 浏览六级树 | ✅ | 展开/折叠，只读展示 |
| 状态标记 | ✅ | StatusChip 显示草稿/已发布 |
| 试听预览 | ✅ | PreviewScreen 逐场景逐步骤引导 |

### 待实现功能

#### P0 — 课程结构编辑（CRUD）

**新建层级节点**

| 项 | 定义 |
|---|------|
| 触发 | 课程研发页各级列表末尾的「+ 新建」按钮 |
| 范围 | Program、Course、Phase、Lesson 四级 |
| 行为 | 在当前层级下创建一个空节点，名称默认可编辑，焦点自动落入 |
| 数据 | 新节点 status 默认 `draft`，sortOrder 自动设为当前同级最大值 +1 |
| Scene 和 Step | 不单独新建，随 Lesson 编辑时填充 |

**编辑层级节点**

| 项 | 定义 |
|---|------|
| 触发 | 点击节点标题进入编辑态，或右侧面板编辑按钮 |
| 范围 | Program、Course、Phase、Lesson 四级的名称、描述字段 |
| 行为 | 编辑态底部展示 [保存] [取消] 操作栏，未保存时节点显示未保存标记 |
| 约束 | 不涉及 Scene/Step 的内容编辑（那是课时编辑器的范围） |

**删除层级节点**

| 项 | 定义 |
|---|------|
| 触发 | 节点右键菜单或操作按钮 |
| 范围 | Program、Course、Phase、Lesson 四级 |
| 行为 | 弹出确认对话框，提示被删除项包含的子级数量 |
| 级联 | 删除 Program → 其下所有 Course/Phase/Lesson 不再展示，但不删除独立资源 |
| 约束 | 不可删除已发布状态的节点 |

#### P1 — 发布流程

**状态切换**

| 项 | 定义 |
|---|------|
| 触发 | 节点操作菜单中的「发布」/「下架」按钮 |
| 范围 | Program、Course、Lesson 三级（Phase 不独立发布，随 Course 发布） |
| 行为 | draft → published：节点状态标记更新，树中样式变化 |
| 约束 | 发布 Course 时检查其下所有 Lesson 的 status，有草稿课时则提示确认 |

#### P1 — 排序调整

**拖拽排序**

| 项 | 定义 |
|---|------|
| 触发 | 长按节点拖拽 |
| 范围 | 同级节点之间（Course 在 Program 内排序、Phase 在 Course 内排序等） |
| 行为 | 拖拽时显示插入位置指示线，松手后保存新顺序 |
| 约束 | 不可跨级拖拽（如不能把 Course 拖成 Phase） |

#### P2 — 蓝图互通

**从蓝图导入**

| 项 | 定义 |
|---|------|
| 触发 | 「导入蓝图」按钮 → 文件选择器或粘贴 JSON |
| 输入 | 与 workflow.md 蓝图示例格式一致的 JSON |
| 行为 | 解析后直接插入课程树，自动分配 ID（覆盖输入 ID） |
| 冲突处理 | 相同 `name` 的节点提示「覆盖 / 跳过 / 保留两者」 |

**导出为蓝图**

| 项 | 定义 |
|---|------|
| 触发 | 右键菜单或操作栏「导出」按钮 |
| 输出 | 选中节点及其子级导出为兼容蓝图格式的 JSON |
| 用途 | 导出后可被 CLI 处理，或分享给其他 Studio 实例导入 |

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
