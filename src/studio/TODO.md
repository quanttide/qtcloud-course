# TODO — v0.0.7

> 沿用现有模式：不可变模型、ChangeNotifier Service、StatelessWidget + Provider。

---

## P0 — 考核工作流

### 学生提交

- [ ] 提交列表增加提交状态筛选（已提交/未提交/迟交/重交）
- [ ] 未提交学生标记（灰色头像 + "未提交"标签）
- [ ] 模拟学生提交按钮（assets 模式：点击生成一条 Submission 记录）
- [ ] 提交内容字段（Submission.content: text/attachment 文本内容 + 文件链接）

### 批量评分

- [ ] 全班评分面板（一个考核的所有提交集中在一个页面，无需点进每个提交编辑）
- [ ] 批量评分模式（连续评分：评分完一个自动跳到下一个未评分）
- [ ] 评分状态标记（已评分/未评分/部分评分）
- [ ] 快捷键支持（Enter 提交评分，自动跳转下一个）

### 成绩概览

- [ ] 考核详情页顶部统计卡片（平均分 / 最高分 / 最低分 / 及格率）
- [ ] 分数分布柱状图（0-59 / 60-69 / 70-79 / 80-89 / 90-100 五档）
- [ ] 及格/不及格人数环形图
- [ ] 导出成绩为 CSV

---

## P1 — 考试模式

### 题型支持

- [ ] Answer 模型（`lib/models/answer.dart`）：id, submissionId, questionIndex, type(choice/fill/text), content, correctAnswer, isCorrect
- [ ] ChoiceAnswer 模型（选择题）：options List<String>, selectedIndex, correctIndex
- [ ] FillAnswer 模型（填空题）：text, expectedText, isExactMatch
- [ ] TextAnswer 模型（简答题）：text, wordLimit
- [ ] 考试创建 UI：支持添加题目（选择题/填空题/简答题混合）

### 自动评分

- [ ] 选择题自动评分（selectedIndex == correctIndex）
- [ ] 填空题精确/模糊匹配评分
- [ ] 自动评分结果汇总（得分/总分/正确率）

### 考试计时

- [ ] 考试起止时间字段（Assessment.startTime, Assessment.endTime）
- [ ] 倒计时显示（顶部固定栏，到时间自动提交）
- [ ] 考试状态（not_started / in_progress / submitted / graded）

---

## P2 — 技术债

- [ ] CI pipeline：push 自动跑 `flutter test` + `dart analyze`
- [ ] 消除三 Service `_apiPost/Put/Delete` 重复（提取为 mixin）
- [ ] `analysis_options.yaml` 开启 `prefer_const_constructors` 等 lint

---

## 测试与验证

- [ ] `flutter test` 全部通过
- [ ] `dart analyze` 零报错
