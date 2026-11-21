# qtcloud-course-studio

量潮课程云 Studio：**课时工作台**。单页两栏——左侧写课时 Markdown，右侧实时预览学员端形态。

形态照 `qtcloud-media` 的 studio：左内容、右预览。缺省纯本地，直接打开 `data/profile/<course>/lessonN-*/` 正本目录，保存即写回正本，Studio 不留第二份副本。

## 为什么这么做

**打开即放示例数据**：`assets/sample-lesson.md`（AI创意第 1 课）在启动时装进内存——页面空着就看不出这是干什么的，现在左栏是它的 Markdown、右栏是学员端形态，一眼看懂。示例与浏览器暂存都不是正本，保存时提示「已存到内存（不是正本）」（`isFileBacked`）。

**同一份课时内容过去有三份**（课件 HTML、教程脚本、lite 的 `data/lessons/*.ts`），靠人手抄对齐，改一句要发一个 patch——2026-11-21 AI创意第 3 步一句话连发 0.2.4 / 0.2.5 / 0.2.6 三个版本，每版都要等肉眼比对。工作台把对齐挪到发版之前：

- **右边就是学员看到的**：按与 qtclass-lite 相同的块模型渲染（本仓 `lib/models/lesson.dart` ↔ lite `src/models/lesson.ts`，两边字段改动必须同步）
- **左边就是正本**：桌面端编辑 `data/profile` 里的 Markdown，保存落盘，没有中间副本；浏览器端没有文件系统，走内存（打开本机 .md 装入、保存另存为下载），读写层按平台分叉在 `lesson_store_io.dart` / `lesson_store_web.dart`（`dart:io` 在 Web 上会直接抛错，曾因此灰屏）
- **解析当场报错**：缺标题、围栏未闭合、块悬空都直接显示，不静默吞掉

## 运行 / 测试

```bash
flutter run           # 本地运行
flutter analyze       # 零告警
flutter test          # 全部通过
```

打开内容：点右上「打开课时目录」选 `data/profile/<course>/lessonN-*/`，左栏选文件编辑，右栏实时预览，点「保存」写回。

## 课时 Markdown 约定

规则只有一份，在 `lib/services/lesson_md.dart`。围栏写成 **MyST directive 形状**（`​```{copy}`，与仓内 `​```{tab-set}`、`​:::{tab-item}` 同形），所以在 MyST 语义下它是自定义 directive，不是平行方言；语义归课时契约（下面七种），不迁就 MyST 的 admonition：

| 写法 | 解析结果 |
|------|---------|
| `# 课时标题` | 课时标题（只认第一个），其后第一段是 lede |
| `## 步骤标题` | 新步骤，序号按顺序从 1 起；其后第一段是「要做的动作」 |
| ` ```{copy} 标签 ` | 一键复制块，正文原样作 text |
| ` ```{note} 标签 ` | 预期结果块，正文逐行 |
| ` ```{code} 标签 ` | 回显块，以 `✓` 开头的行记为完成态 |
| ` ```{link} 标签 ` | 链接块，正文第一行 url、其余是 tip |
| ` ```{image} 标签 ` | 对照图块，正文第一行 src、第二行 alt、其余是 tip |
| ` ```{tip} ` / ` ```{foot} ` | 课末提示 / 页脚一句话 |

## 结构

| 文件 | 职责 |
|------|------|
| `lib/models/lesson.dart` | 课时契约，与 lite 的 `Lesson` 同形 |
| `lib/services/lesson_md.dart` | Markdown → Lesson 解析，规则唯一 |
| `lib/services/lesson_store.dart` | 存储接口与按平台选择（桌面读写正本目录 / 浏览器内存），拒绝跨目录文件名 |
| `assets/sample-lesson.md` | 打开即放示例课时 |
| `lib/widgets/lesson_preview.dart` | 学员端形态渲染，结构照 lite 的 `LessonDetail.tsx` |
| `lib/screens/workbench_screen.dart` | 单页两栏：目录 / 文件 / 编辑器 + 预览 |
