# TODO — v0.0.7

## P0 — 考核导航独立

- [ ] 侧边栏新增「考核管理」tab，与「班级管理」平级
- [ ] `AssessmentManagementScreen`：考核全局视图（全部考核列表，按班级分组）
- [ ] `ClassScreen` → `ClassManagementScreen` 重命名

## P1 — 考核工作流

- [ ] 学生提交（提交状态筛选、未提交标记、模拟提交、提交内容字段）
- [ ] 批量评分（全班集中评分面板、连续评分模式、评分状态标记）
- [ ] 成绩概览（统计卡片、分布图、及格率、CSV 导出）

## P2 — 考试模式

- [ ] 题型支持（Answer 模型：选择题/填空题/简答题）
- [ ] 自动评分（预设答案匹配）
- [ ] 考试计时（起止时间、倒计时、状态流转）

## P3 — 技术债

- [ ] CI：push 自动跑 `flutter test` + `dart analyze`
- [ ] 三 Service `_apiPost/Put/Delete` 提取为 mixin
- [ ] `analysis_options.yaml` 开启 `prefer_const_constructors` 等 lint

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错
