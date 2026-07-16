# TODO — v0.1 课程制作

> 补齐 Scene 编辑器 + 分支选项 + 本地持久化，不依赖 Provider/CLI。

## P0 — Scene 编辑器

- [x] Scene 编辑器页面：创建/编辑场景（场景名、描述、课时归属）
- [x] 步骤编辑器：添加/编辑/删除/排序步骤
- [x] 分支选项 UI：步骤内分支选择、跳转目标场景配置

## P1 — 数据持久化

- [x] 本地模式默认：不依赖 Provider API，默认读取本地 JSON
- [x] 本地持久化：编辑内容自动保存到 `~/.qtcloud-course/data/`
- [x] JSON 导出/导入：文件选择器导入导出课程结构
- [ ] 导入预览：确认/回滚导入结果
- [ ] JSON schema 校验 + 错误提示

## P2 — 环境与 CI

- [ ] 环境配置统一（`api_base_url`、`data_dir`）
- [ ] iOS 构建验证（`flutter build ios`）
- [ ] Android 构建验证（`flutter build apk`）
- [ ] CI：push 自动跑 `flutter test` + `dart analyze`

## P3 — 技术债

- [ ] 三 Service `_apiPost/Put/Delete` 提取为 mixin
- [ ] GUI 测试并行化
- [ ] `analysis_options.yaml` lint 规则

---

## 验证

- [x] `dart analyze` 零报错
- [x] `flutter test` 165 个全通过
