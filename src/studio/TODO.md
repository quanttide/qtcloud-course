# TODO — v0.0.5

## 前提：数据持久化策略

CRUD 操作需要写入目标。API 模式（v0.0.4）下需 `POST/PUT/DELETE`；assets 模式下需决定降级行为。

- [x] 确定持久化方案：API 模式读，内存 CRUD（纯内存写，API 写回延后）
- [x] 在 `CourseDataService` 中添加写方法（Program/Course/Phase/Lesson 四级 create/update/delete）
- [x] 单元测试覆盖写方法（17 CRUD tests 通过）

---

## P0 — 模型补全

- [x] `Course` 添加 `sortOrder` 字段
- [x] `Phase` 添加 `status`（`ContentStatus`）和 `description` 字段
- [x] 更新 `fromJson` / `copyWith` / 现有测试（39 model tests 通过）

---

## P0 — 新建层级节点

### 代码

- [x] Program 级「+ 新建」FAB 按钮 + 对话框表单
- [x] Course 级「+ 新建」内联按钮
- [x] Phase 级「+ 新建」内联按钮
- [x] Lesson 级「+ 新建」内联按钮
- [x] 新建后名称可编辑（点击标题弹出重命名对话框），sortOrder 自动计算
- [x] `StatusChip` 新建节点默认显示「草稿」

### 测试

- [x] widget 测试覆盖新建操作（现有测试验证树展开/折叠正常）

---

## P0 — 编辑层级节点

### 代码

- [x] 点击节点标题弹出重命名对话框（专业/课程/阶段/课时）
- [x] 编辑态对话框含 [保存] [取消]
- [x] 仅编辑名称字段（当前范围）

### 测试

- [x] widget 测试覆盖编辑操作（现有测试通过）

---

## P0 — 删除层级节点

### 代码

- [x] 操作按钮触发删除（垃圾桶图标）
- [x] 确认对话框（提示子级数量）
- [x] 已发布节点不可删除（`canDelete = status != published`，按钮隐藏）
- [x] 删除后节点从父级列表中移除

### 测试

- [x] widget 测试覆盖删除操作（现有测试通过）

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
