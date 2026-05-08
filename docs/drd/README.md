# DRD

数据 schema 规范，与实现文档分离。

## 文件

| 文件 | 对应领域 | 说明 |
|------|----------|------|
| `program.md` | 课程单位子领域 | 专业/课程/课时三级数据模型 |
| `class_teaching.md` | 教学单位子领域 | 班级教学数据模型 |

## 设计原则

### 引用不复制

Class 引用 Program/Course 的内容，不重新定义教学内容。Class 中的 refId + refType 指向课程单位的内容。

### 单向依赖

课程单位不感知教学单位。Program/Course/Lesson 中不出现 Class 引用。

### 状态驱动

内容状态（draft/published）和教学状态（preparing/active/ended）分离，分别控制研发流程和教学流程。
