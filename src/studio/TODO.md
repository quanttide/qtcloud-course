# TODO — 课时工作台

> 定位：qtcloud-course 是研发实验场，Studio 是它的操作台——左写课时、右看学员端形态，把「改一处 → 看到学员看到的字」压在发版之前。

## 已完成（2026-11-21）

- [x] 单页两栏工作台：左栏打开 `data/profile` 课时目录写 Markdown，右栏学员端形态实时预览
- [x] md → Lesson 解析，五种块齐全，规则唯一（`lib/services/lesson_md.dart`），解析失败当场报错
- [x] 保存写回正本目录，Studio 不留副本
- [x] 收敛旧多屏（ProgramScreen / SceneEditorScreen / PreviewScreen）与 Program / Phase 模型

## 下一刀

- [ ] `index.json` 同步：保存时把 steps 写回 profile 的机器可读文件——先定 steps 与 scenes 的对应，不许凭空生成
- [ ] AI创意 / AI工作 / AI教学 在 `data/profile` 补成课时目录（现在只有 html 课件，学员端内容仍是手抄）
- [ ] 目录选择改原生对话框（现在是路径按钮）
- [ ] 远程模式：连 provider 推送（照 qtcloud-media 的 `remote_io`）
- [ ] `studio/*` tag → OSS + CDN 的部署 workflow（本仓还没有）

## 验证

- [x] `flutter analyze` 零告警
- [x] `flutter test` 19 个全通过
