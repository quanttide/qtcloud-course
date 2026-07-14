# TODO — v0.0.7 

## P0 — 基础设施

- [ ] CI pipeline：push 自动跑 `flutter test` + `dart analyze`
- [ ] `analysis_options.yaml` 开启额外 lint（`prefer_const_constructors`、`avoid_print` 等）
- [ ] 拖拽排序 widget 测试
- [ ] 消除 `dart analyze` 余留 info（`use_null_aware_elements`）

## P1 — 评审重构

- [ ] `_apiPost/Put/Delete` 提取为 mixin（消除三 Service 重复 + 统一 `debugPrint` 异常日志）
- [ ] `_buildTile` 拆分为 `_buildProgramTile` / `_buildCourseTile` / `_buildPhaseTile` / `_buildLessonTile`
- [ ] 拖拽约束 `ids[0]`/`ids[1]`/`ids[2]` 提取为命名结构
- [ ] 导航配置集中化（sidebar / _titles / _screens 三处合并为一处）
- [ ] `#5` 补全：`data_service` / `assessment_service` API 写回异常日志（当前仅 program_service 有 `debugPrint`）
- [ ] `StatusChip.dynamic status` 改为类型安全（`Object` + 运行时检查）
- [ ] `_findLessonInTree` 四层循环 — 将 `_lessonCache` 扩展到缓存树内 scenes

## P2 — 低优先级

- [ ] `Step` UI 显示 `order + 1`（当前从 0 开始）
- [ ] `Scene.videoUrl` 真实播放器集成
- [ ] Assessment 日期字段 `String` → `DateTime`
- [ ] `file_picker` 平台兼容性标记（桌面专用，移动端应隐藏导入/导出按钮）
- [ ] `_SimpleItem` / `_buildSectionPanel` 归入 `DashboardScreen` 作为私有静态成员
- [ ] `_showScoreDialog` 学生姓名查询从 `fold` 改为 `firstWhereOrNull`
- [ ] 硬编码颜色统一使用 `Theme.of(context).colorScheme`
- [ ] `_screens` static const 加注释说明单例约束

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错
