# ROADMAP — Studio

## 当前状态：v0.0.1

Studio 是课程编排的编辑器后台，支持 Program→Course→Lesson 三级管理。但数据模型只到 Lesson，没有 Scene/Step，无法预览上课效果。

## 规划

### v0.0.2 — Scene/Step 模型 + 试听预览

将编排深度从 Lesson 延伸到 Scene 和 Step，并在 Studio 内嵌入试听模式。

- [ ] 数据模型新增 Phase、Scene、Step、Choice
  - Phase：id、name、sortOrder、lessons
  - Scene：id、name、title、steps、choices、verifyTip
  - Step：order、content
  - Choice：label、targetSceneId
- [ ] Course 从直接包含 Lesson 改为包含 Phase → Lesson（与 provider 对齐）
- [ ] 课程研发页 Lesson 展开后显示 Scene 列表
- [ ] Scene 可展开显示 Step 列表及验证提示
- [ ] Lesson 行末增加"试听"按钮 → 打开类似 lesson1.html 的预览页
- [ ] 试听页从本地 assets 加载数据（参考 `data/profile/vibe-coding/lesson1.json` 结构），不走网络请求
