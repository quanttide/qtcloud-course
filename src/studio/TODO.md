# TODO — v0.0.5

## 前提：数据持久化策略

CRUD 操作需要写入目标。API 模式（v0.0.4）下需 `POST/PUT/DELETE`；assets 模式下需决定降级行为。

- [ ] 确定持久化方案（API 写回 / 纯内存 / 本地存储）
- [ ] 在 `CourseDataService` 中添加对应写方法（`createProgram` / `updateProgram` / `deleteProgram` 等）
- [ ] 单元测试覆盖写方法

---

## P0 — 模型补全

- [ ] `Course` 添加 `sortOrder` 字段（当前缺失，影响拖拽排序）
- [ ] `Phase` 添加 `status`（`ContentStatus`）和 `description` 字段（当前缺失，影响编辑和状态展示）
- [ ] 更新 `fromJson` / `copyWith` / 现有测试

---

## P0 — 新建层级节点

### 代码

- [ ] Program 级「+ 新建」按钮 + 表单
- [ ] Course 级「+ 新建」按钮 + 表单
- [ ] Phase 级「+ 新建」按钮 + 表单
- [ ] Lesson 级「+ 新建」按钮 + 表单
- [ ] 新建后名称可编辑，焦点落入，sortOrder 自动计算
- [ ] `StatusChip` 新建节点默认显示「草稿」

### 测试

- [ ] widget 测试覆盖新建操作

---

## P0 — 编辑层级节点

### 代码

- [ ] 点击节点标题进入编辑态
- [ ] 编辑态底部 [保存] [取消] 操作栏
- [ ] 未保存标记
- [ ] 仅编辑名称和描述字段

### 测试

- [ ] widget 测试覆盖编辑操作

---

## P0 — 删除层级节点

### 代码

- [ ] 右键菜单或操作按钮触发删除
- [ ] 确认对话框（提示子级数量）
- [ ] 已发布节点不可删除
- [ ] 删除后节点从父级列表中移除

### 测试

- [ ] widget 测试覆盖删除操作

---

## P1 — 发布与排序

### 发布/下架

- [ ] Program 发布/下架
- [ ] Course 发布/下架（检查草稿 Lesson）
- [ ] Lesson 发布/下架
- [ ] Phase 不独立发布（仅展示父级状态）
- [ ] widget 测试覆盖发布操作

### 拖拽排序

- [ ] 同级节点拖拽（含插入指示线）
- [ ] 不可跨级拖拽约束
- [ ] 排序后数据持久化
- [ ] widget 测试覆盖拖拽

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错

---

## 发布

- [ ] 在 `pubspec.yaml` 中更新版本号至 `0.0.5`
- [ ] 运行 `flutter test` 全部通过
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.5`
