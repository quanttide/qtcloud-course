# TODO — v0.1 课程制作

> 补齐 Scene 编辑器，不再依赖手写 JSON，打通从蓝图到互动课时的端到端链路。

## P0 — Scene 编辑器

- [x] Scene 编辑器页面：创建/编辑场景（场景名、描述、课时归属）
- [x] 步骤编辑器：添加/编辑/删除/排序步骤（文本、选项、分支条件）
- [x] 编辑器与 Provider API 打通（CRUD Scene/Step）
- [ ] 分支选项 UI：步骤内分支选择、跳转逻辑配置

## P1 — 数据管线

- [ ] 一键导入 CLI blueprint 输出的结构化 JSON 为课程结构（Program → Course → Phase → Lesson）
- [ ] 导入预览：确认/回滚导入结果
- [ ] JSON schema 校验 + 错误提示

## P2 — 环境与 API

- [x] 启动模式改为默认走 Provider API（`http://localhost:8080`）
- [x] 本地 JSON 降级为离线回退方案（API 失败自动回退 + 离线模式指示器）
- [ ] 环境配置统一（`api_base_url`、`data_dir`）

## P3 — 多平台与 CI

- [ ] iOS 构建验证（`flutter build ios`）
- [ ] Android 构建验证（`flutter build apk`）
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`
- [ ] CI：覆盖率门禁

## P4 — 技术债

- [ ] 三 Service `_apiPost/Put/Delete` 提取为 mixin
- [ ] `analysis_options.yaml` 开启 `prefer_const_constructors` 等 lint
- [ ] GUI 测试并行化：16 个 pytest 错误修复（无 Flutter 进程时跳过标记）

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错
- [ ] Scene 编辑器：创建 → 编辑 → 保存 → 回读链路完整
- [ ] 数据管线：CLI 输出 JSON → Studio 导入 → Provider 持久化
