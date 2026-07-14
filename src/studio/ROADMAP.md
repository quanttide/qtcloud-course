# ROADMAP — Studio

## v0.0.5（当前）— 课程编辑可用

课程编排从只读变为可编辑，完成课前（课程研发）子领域的 CRUD 闭环。

### Phase 1（P0）：四级 CRUD ✅

- Program / Course / Phase / Lesson 新建/编辑/删除
- 已发布节点不可删除，删除确认提示子级数量
- 新建节点后 `sortOrder` 自动计算

### Phase 2（P2）：双轨互通

文件导入/导出，独立于发布和排序，实现成本较低。

- 文件导出：`jsonEncode(programs)` → 保存本地 `.json`
- 文件导入：选择 `.json` → 解析 → 合并到当前树
- 冲突处理策略（覆盖/跳过/保留两者）

### Phase 3（P1）：发布与排序

放在 P2 之后，因为拖拽排序在嵌套树中实现成本较高（需扁平化列表 + 缩进）。

- 发布/下架操作（Program / Course / Lesson）
- Phase 有独立 `status` 字段和展示，但不提供发布/下架按钮
- 发布 Course 时检查 Lesson 草稿并提示
- 同级节点拖拽排序（需重构为扁平缩进列表，再用 `ReorderableListView`）

### 限制说明

- API 写回延后：当前 CRUD 仅修改内存，不写回服务端。API 模式下需切换为 POST/PUT/DELETE。

### 交付标准

```
flutter test       # ✅ 全部通过
dart analyze       # ✅ 零报错
```

---

## v0.0.6 — 教学与考核管理

基于 specification 最新定义的 class/ 和 assessment/ 子领域，将"教学管理"tab 做实。

### 班级管理

- 班级列表（从 API / assets 加载）
- 班级详情页（关联专业/课程、起止日期、进度）
- 学生列表展示（引用 Student 规格）
- 教师配置（引用 Teacher 规格）

### 考核管理

- 考核列表（按班级筛选，展示 HOMEWORK / EXAM）
- 考核详情（类型、时间、满分、及格线）
- 提交列表 + 状态标记（Submitted / Late / Resubmitted）
- 评分操作（教师打分 + 评语）

### 交付标准

```
flutter test       # ✅ 全部通过
flutter run -d linux  # 验收：教学管理 tab 全流程
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
课前（课程研发）────→  课前 + 课中 + 考核（规格）────→  三领域全流程
课程树 CRUD              班级管理 / 考核管理            API 默认
双轨互通                  本地 + API 双数据源           多平台构建
```
