# TODO — v0.0.5

## v0.0.5 回顾（已完成）

### P0 — 四级 CRUD ✅

- [x] 模型补全（Course.sortOrder, Phase.status/description）
- [x] CourseDataService CRUD 方法 + 17 个单元测试
- [x] 新建四级节点 UI（Program → Lesson 新建对话框 + 内联按钮）
- [x] 编辑节点（点击标题弹出重命名，sortOrder 自动计算）
- [x] 删除节点（确认提示、已发布隐藏删除按钮）
- [x] 39 个 model tests + widget tests 全部通过

---

## P2 — 双轨互通（先做，成本较低）

### 文件导出

- [x] AppBar 导出按钮（下载图标）
- [x] 序列化 `_programs` 树为 JSON（`exportProgramsJson`）
- [x] `file_picker` 选择目录 + `dart:io` 写文件

### 文件导入

- [x] AppBar 导入按钮（上传图标）
- [x] `file_picker` 选择 `.json` 文件
- [x] 合并策略：已存在 ID 覆盖，新 ID 追加

### 测试

- [x] `toJson` roundtrip 测试
- [x] 合并测试（新 + 已存）
- [x] 异常 JSON 处理测试

---

## P1 — 发布与排序

### 说明

- Phase 有独立 `status` 字段和 `StatusChip` 展示，但不提供发布/下架按钮
- 拖拽排序在嵌套树中实现成本较高，当前树靠 `Column` + 展开折叠实现，
  需先重构为扁平缩进列表，再接入 `ReorderableListView`
- **API 写回延后**：当前 CRUD 仅操作内存，不写回服务端

### 发布/下架

- [ ] 操作按钮 + 确认弹框
- [ ] Program 发布/下架
- [ ] Course 发布/下架（检查草稿 Lesson，有则提示确认）
- [ ] Lesson 发布/下架
- [ ] 下架/草稿 Lesson 在 PreviewScreen 中提示不可试听
- [ ] widget 测试覆盖发布操作

### 拖拽排序

- [ ] 树渲染重构为扁平缩进列表
- [ ] 同级节点拖拽（含插入指示线）
- [ ] 不可跨级拖拽约束
- [ ] 排序后调用 `updateXxx(sortOrder: ...)` 持久化
- [ ] widget 测试覆盖拖拽

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错

---

## 发布

- [ ] 同步更新 `pubspec.yaml` 和 `lib/version.dart` 版本号至 `0.0.5`
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.5`
