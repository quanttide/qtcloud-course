# ROADMAP — Studio

## 当前状态：v0.0.1

Studio 是课程编排的编辑器后台，支持 Program→Course→Lesson 三级管理。但数据模型只到 Lesson，没有 Scene/Step，无法预览上课效果。

## 规划

### v0.0.2 — Scene/Step 模型 + 试听预览

将编排深度从 Lesson 延伸到 Scene 和 Step，并在 Studio 内嵌入试听模式。

- [ ] 数据模型新增 Phase、Scene、Step、Choice
  - Phase：id、name、sortOrder、lessons: List&lt;Lesson&gt;
  - Scene：id、name、title、steps、choices、verifyTip
  - Step：order、content
  - Choice：label、targetSceneId
- [ ] Course.lessons → Course.phases: List&lt;Phase&gt;；Lesson 新增 sortOrder 和 scenes: List&lt;Scene&gt;
- [ ] DataService 新增 `loadLesson(String lessonId)` 按需加载课时 Scene/Step 详情
- [ ] 课程研发页 Program → Course → Phase → Lesson → Scene → Step 六级展开树
- [ ] Lesson 行末增加"试听"按钮 → PreviewScreen
- [ ] PreviewScreen 全屏课堂页面，通过 DataService.loadLesson 获取数据
- [ ] 集成测试覆盖启动、页面跳转和试听全流程
- [ ] 开发文档（doc/）记录架构、数据模型和测试策略
