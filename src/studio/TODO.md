# TODO 

## P0 — API 写回

- [x] ProgramService CRUD 同步 POST/PUT/DELETE（API 模式时）
- [x] CourseDataService CRUD 同步 POST/PUT/DELETE
- [x] AssessmentService CRUD 同步 POST/PUT/DELETE
- [x] 单元测试覆盖 API 写回（MockClient 验证 HTTP 调用，22 个测试）

---

## P1 — 产品打磨

### 拖拽排序

- [x] 树渲染重构为扁平缩进列表（替换嵌套 Column + 展开折叠）
- [x] 同级节点拖拽（`ReorderableListView` + 插入指示线）
- [x] 不可跨级拖拽约束
- [x] 排序后调用 `updateXxx(sortOrder: ...)` 持久化
- [ ] widget 测试覆盖拖拽

### ID 生成

- [x] `_nextId()` 改用 `Uuid`（`uuid` 包）替代自增计数器

### 仪表盘

- [x] 整合三领域指标（课程数 / 班级数 / 待评分考核数）

### CI

- [ ] push 自动跑 `flutter test` + `dart analyze`

---

## 测试与验证

- [x] `flutter test` 全部通过（165/165）
- [x] `dart analyze` 零报错

---

## 发布

- [ ] 同步更新 `pubspec.yaml` 和 `lib/version.dart` 版本号至 `0.0.7`
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.7`
