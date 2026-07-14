import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../services/assessment_service.dart';
import 'assessment_detail_screen.dart';

class AssessmentListScreen extends StatelessWidget {
  final String classId;
  final String className;

  const AssessmentListScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssessmentService>();
    final assessments = service.getAssessmentsByClass(classId);

    return Scaffold(
      appBar: AppBar(title: Text('$className - 考核管理')),
      body: assessments.isEmpty
          ? const Center(child: Text('暂无考核'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assessments.length,
              itemBuilder: (_, i) {
                final a = assessments[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      a.type == AssessmentType.exam
                          ? Icons.quiz
                          : Icons.home_work,
                      size: 32,
                      color: a.type == AssessmentType.exam
                          ? Colors.deepPurple
                          : Colors.teal,
                    ),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('截止: ${a.deadline}  |  ${a.fullScore}分'),
                    trailing: Text(a.type.label,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentDetailScreen(
                          assessment: a,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
