# TODO — v0.0.6

> 沿用现有模型规范：不可变类、`fromJson` + `copyWith` + `toJson`。

## P0 — 模型层

- [ ] `Student`（`lib/models/student.dart`）：`id`, `name`, `email`, `avatar`
- [ ] `Teacher`（`lib/models/teacher.dart`）：`id`, `name`, `email`, `title`
- [ ] `Assessment`（`lib/models/assessment.dart`）：`id`, `classId`, `type`(`AssessmentType`), `title`, `fullScore`, `passScore`, `deadline`
- [ ] `Submission`（`lib/models/submission.dart`）：`id`, `assessmentId`, `studentId`, `status`(`SubmissionStatus`), `score`, `comment`, `submittedAt`
- [ ] 枚举：`AssessmentType`（homework/exam）、`SubmissionStatus`（submitted/late/resubmitted）
- [ ] `ClassTeaching` 补充 `teacherIds`（`List<String>`）、`studentIds`（`List<String>`）
  - `refType`/`refId` 继续指向课程内容；`teacherIds`/`studentIds` 指向人员
- [ ] 单元测试覆盖所有新模型（fromJson/toJson/copyWith/默认值）

---

## P1 — 服务层 + UI 层

### ClassScreen 改造

- [ ] 班级信息卡片（名称、引用专业、起止日期、进度）—— 改造现有底部弹框为右侧详情面板
- [ ] 学生列表（`studentIds` → 加载 `Student` 列表，内嵌滚动）
- [ ] 教师配置入口（`teacherIds` → 显示 `Teacher` 列表）

### 考核管理

- [ ] `AssessmentService`（`lib/services/assessment_service.dart`）：考核 CRUD + 提交管理 + 评分
- [ ] 考核列表（按班级筛选，展示类型/标题/截止日期）
- [ ] 考核详情页（基本信息 + 提交列表 + 状态标记）
- [ ] 评分弹框（打分 + 评语 + 提交）
- [ ] widget 测试覆盖考核和班级管理交互

---

## P2 — 技术债

### API 写回

- [ ] ProgramService CRUD 同步 POST/PUT/DELETE（API 模式时）
- [ ] CourseDataService 同步 POST/PUT/DELETE
- [ ] 单元测试覆盖 API 写回（MockClient）

### ID 生成

- [ ] `_nextId()` 改用 `Uuid`（`uuid` 包）替代自增计数器

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错

---

## 发布

- [ ] 同步更新 `pubspec.yaml` 和 `lib/version.dart` 版本号至 `0.0.6`
- [ ] 更新 `CHANGELOG.md`
- [ ] 创建 git tag `studio/v0.0.6`
