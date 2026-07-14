# ROADMAP — Studio

## v0.0.5 — 课程结构编辑（P0）

**现状**：课程编排树只读，用户能浏览六级结构但无法创建、编辑、删除节点。

**目标**：实现课程结构的 CRUD，让用户能通过 Studio 完成课程从无到有的搭建，不再依赖 CLI 导入或手动改 JSON。

### 前提：数据持久化

编辑操作需要写入目标。v0.0.5 需要先决定持久化策略：
- API 写回（`POST/PUT/DELETE`）—— 配合 v0.0.4 的 Provider API
- 纯内存 —— 刷新后重置，适合原型验证
- localStorage / SharedPreferences —— 离线可用

策略在 TODO 中前置为 P0 的第一个任务。

### 功能列表

#### P0 — 模型补全

Course 添加 `sortOrder` 字段，Phase 添加 `status` 和 `description` 字段。当前模型缺失这些字段，是 CRUD 和排序的前提。

#### P0 — 新建层级节点

- Program、Course、Phase、Lesson 四级支持新建
- 每级列表末尾显示「+ 新建」按钮
- 新建后名称可编辑，焦点自动落入
- 新节点 status 默认 `draft`，sortOrder 自动设为同级最大值 +1
- Scene 和 Step 不单独新建（随 Lesson 编辑时填充）

#### P0 — 编辑层级节点

- Program、Course、Phase、Lesson 四级的名称和描述字段支持编辑
- 点击节点标题进入编辑态，底部 [保存] [取消]
- 未保存时节点显示未保存标记
- 不涉及 Scene/Step 的内容编辑

#### P0 — 删除层级节点

- Program、Course、Phase、Lesson 四级支持删除
- 弹出确认对话框，提示被删除项包含的子级数量
- 删除后节点从树中移除（内部表现为从父级列表中移除）
- 不可删除已发布状态的节点

#### P1 — 发布/下架

- Program、Course、Lesson 三级支持发布和下架
- Phase 不独立发布，随 Course 发布
- 发布 Course 时检查下属 Lesson 状态，有草稿课时则提示确认

#### P1 — 拖拽排序

- 同级节点之间拖拽排序（Course 在 Program 内、Phase 在 Course 内等）
- 拖拽时显示插入位置指示线
- 不可跨级拖拽

### 发布标准

```
flutter test                          # ✅ 全部通过
dart analyze                          # ✅ 零报错
```

---

## v0.0.6+（规划中）

- **P2 蓝图互通**：导入/导出蓝图 JSON
- **课时内容编辑器**：Scene→Step 的编排界面
- **搜索与筛选**：课程树搜索框
- **批量操作**：批量发布、批量删除
