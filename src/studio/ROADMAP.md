# ROADMAP — Studio

## v0.0.5 ✅ — 课程编辑可用

课程编排从只读变为可编辑，完成课前（课程研发）子领域的 CRUD 闭环。

- 四级 CRUD（Program/Course/Phase/Lesson 新建/编辑/删除）✅
- 发布/下架 + 草稿检查 ✅
- JSON 双轨互通（导入/导出）✅
- 底部导航 → 侧边导航（Sidebar 240px）✅
- Service 拆分（ProgramService + CourseDataService）✅

### 遗留（defer 到后续版本）

- 拖拽排序（需扁平化树重构）
- API 写回
- 拖拽排序后的 widget 测试

---

## v0.0.6 — 教学管理做实

将"教学管理"tab 从只读列表变为可操作的班级运营和考核管理模块。

### P0 — 模型层

- [ ] 新建 Student/Teacher/Assessment/Submission 模型（不可变、fromJson + copyWith + toJson）
- [ ] ClassTeaching 补充 `teacherIds`, `studentIds`（与现有 `refType`/`refId` 职责分离：ref 指向课程内容，ids 指向人员）

### P1 — 服务层 + UI 层

- [ ] 扩展现有 `CourseDataService` 添加班级 CRUD（班级本身已是 ClassTeaching，只补 create/update/delete）
- [ ] 新建 `AssessmentService`（考核 CRUD + 提交管理 + 评分）
- [ ] 改造 `ClassScreen`：从列表 → 列表 + 详情面板（班级信息、学生列表、关联考核）
- [ ] 新增考核列表 + 考核详情 + 评分弹框

### P2 — 技术债（选做，视进度）

- [ ] API 写回（ProgramService + CourseDataService CRUD 同步 POST/PUT/DELETE）
- [ ] ID 生成器改用 UUID（`uuid` 包）
- [ ] 拖拽排序延后（v0.0.5 遗留，不纳入 v0.0.6 承诺范围）

### 交付标准

```
flutter test       # ✅ 全部通过
dart analyze       # ✅ 零报错
flutter run -d linux  # 教学管理 tab 全流程可操作
```

---

## v0.1.0 — 产品闭环

三领域全流程可用：从课程研发 → 教学实施 → 考核评估。

- 仪表盘：整合三领域关键指标（课程数/班级数/待评分）
- API 模式默认（`--dart-define=API_BASE_URL` 降级为可选）
- Windows / macOS 构建验证
- CI pipeline：push 自动跑测试 + GUI 测试

---

## 架构演进

```
v0.0.5                   v0.0.6                       v0.1.0
课前（课程研发）────→  教学管理做实（班级/考核）───→ 三领域全流程
课程树 CRUD              模型层 Student/Teacher        API 默认
双轨互通                  Assessment/Submission       多平台构建
Sidebar 布局              ClassScreen 改造             CI pipeline
```
