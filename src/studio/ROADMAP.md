# ROADMAP — Studio

### P0 — API 写回

- ProgramService/CourseDataService/AssessmentService CRUD 同步 POST/PUT/DELETE
- 单元测试覆盖 API 写回（MockClient）

### P1 — 产品打磨

- 拖拽排序（树扁平化 + ReorderableListView）
- ID 生成器改用 UUID
- 仪表盘三领域指标整合
- CI pipeline：push 自动跑测试

### 交付标准

```
flutter test       # ✅ 全部通过
dart analyze       # ✅ 零报错
```
