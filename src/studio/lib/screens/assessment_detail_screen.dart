import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/submission.dart';
import '../services/assessment_service.dart';
import '../services/data_service.dart';


class AssessmentDetailScreen extends StatelessWidget {
  final Assessment assessment;

  const AssessmentDetailScreen({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final assessmentService = context.watch<AssessmentService>();
    final courseDataService = context.read<CourseDataService>();
    final studentNames = {
      for (final s in courseDataService.getStudentsByClass(assessment.classId))
        s.id: s.name,
    };
    final submissions = assessmentService.getSubmissions(assessment.id);

    return Scaffold(
      appBar: AppBar(title: Text(assessment.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 考核基本信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        assessment.type == AssessmentType.exam
                            ? Icons.quiz
                            : Icons.home_work,
                        color: assessment.type == AssessmentType.exam
                            ? Colors.deepPurple
                            : Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Text(assessment.type.label,
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow('满分', '${assessment.fullScore}'),
                  _infoRow('及格线', '${assessment.passScore}'),
                  _infoRow('截止日期', assessment.deadline),
                  const SizedBox(height: 8),
                  Text('提交数: ${submissions.length}',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 提交列表
          Text('提交列表 (${submissions.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (submissions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('暂无提交', style: TextStyle(color: Colors.grey[500]))),
              ),
            )
          else
            ...submissions.map((s) {
              final studentName = studentNames[s.studentId] ?? s.studentId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(studentName.isNotEmpty
                        ? studentName[0]
                        : '?'),
                  ),
                  title: Text(studentName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _statusBadge(s.status),
                          const SizedBox(width: 8),
                          Text('提交: ${s.submittedAt}',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      if (s.score != null)
                        Text('得分: ${s.score}',
                            style: TextStyle(
                                color: s.score! >= assessment.passScore
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold)),
                      if (s.comment != null && s.comment!.isNotEmpty)
                        Text('评语: ${s.comment}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showScoreDialog(
                        context, assessmentService, s, assessment),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statusBadge(SubmissionStatus status) {
    final color = switch (status) {
      SubmissionStatus.submitted => Colors.blue,
      SubmissionStatus.late => Colors.orange,
      SubmissionStatus.resubmitted => Colors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }

  void _showScoreDialog(BuildContext context,
      AssessmentService service, Submission submission, Assessment assessment) {
    final studentName = context.read<CourseDataService>()
        .getStudentsByClass(assessment.classId)
        .where((s) => s.id == submission.studentId)
        .fold<String>('?', (prev, s) => s.name);
    double score = submission.score ?? 0;
    final commentController =
        TextEditingController(text: submission.comment ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('评分 - $studentName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('满分 ${assessment.fullScore} 分'),
                  const SizedBox(height: 16),
                  Slider(
                    value: score,
                    min: 0,
                    max: assessment.fullScore.toDouble(),
                    divisions: assessment.fullScore,
                    label: score.toInt().toString(),
                    onChanged: (v) =>
                        setDialogState(() => score = v),
                  ),
                  Text('${score.toInt()} 分',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: '评语',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    service.scoreSubmission(
                      submission.id,
                      score,
                      commentController.text.isNotEmpty
                          ? commentController.text
                          : null,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('提交评分'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
