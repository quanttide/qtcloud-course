# 架构

分层：Models → Services → Screens

```
lib/
├── models/       数据模型（Program / Course / Phase / Lesson / Scene / Step / Choice）
├── services/     数据加载与服务（CourseDataService）
└── screens/      页面组件
```

## 数据流

1. 应用启动 → `CourseDataService.load()` 加载 `assets/programs.json` 和 `assets/classes.json`
2. Screens 通过 `Provider` 订阅 `CourseDataService`
3. 试听预览调用 `CourseDataService.loadLesson(lessonId)` 按需加载课时详情
