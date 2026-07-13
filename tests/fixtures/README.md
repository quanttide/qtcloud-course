# Fixtures

模拟数据，用于开发、测试和演示。

## 资源关系

```mermaid
graph LR
    prog1[prog-1 大数据微专业] -- courseIds --> cour1[cour-1 数据工程]
    prog1 -- courseIds --> cour2[cour-2 Python基础]
    prog2[prog-2 AI应用开发] -- courseIds --> cour3[cour-3 机器学习入门]

    cour1 -- courseId --> phase1[phase-1 数据采集阶段]
    cour1 -- courseId --> phase2[phase-2 数据清洗与处理阶段]
    cour2 -- courseId --> phase3[phase-3 Python基础阶段]

    phase1 -- lessonIds --> less1[less-1 数据工程概述]
    phase1 -- lessonIds --> less2[less-2 数据采集技术]
    phase2 -- lessonIds --> less3[less-3 数据清洗与预处理]

    less1 -- lessonId --> scene1[scene-1~3 intro→concepts→summary]
    less2 -- lessonId --> scene4[scene-4~6 sources→tools→practice]

    class1[class-1 浙理班级] -- refId --> prog1
    class3[class-3 线上周末班] -- refId --> prog1
    class2[class-2 杭电班级] -- refId --> cour2
    class4[class-4 暑期集训营] -- refId --> prog2
```

## 文件

| 文件 | 内容 |
|------|------|
| `programs.json` | 3 个专业（含空专业） |
| `courses.json` | 3 门课程 |
| `phases.json` | 4 个阶段，覆盖 3 门课程 |
| `lessons.json` | 8 个课时，部分含入口场景 |
| `scenes.json` | 10 个场景，含分支/终结/汇聚节点 |
| `classes.json` | 4 个班级，引用不同专业/课程 |
