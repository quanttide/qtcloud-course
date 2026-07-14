import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_teaching.dart';
import '../models/enums.dart';
import '../services/data_service.dart';
import '../widgets/status_chip.dart';
import 'assessment_list_screen.dart';

class ClassScreen extends StatelessWidget {
  const ClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourseDataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('教学管理')),
      body: service.classes.isEmpty
          ? const Center(child: Text('暂无数据'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.classes.length,
              itemBuilder: (_, i) {
                final c = service.classes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      switch (c.status) {
                        ClassStatus.active => Icons.play_circle,
                        ClassStatus.preparing => Icons.schedule,
                        ClassStatus.ended => Icons.check_circle,
                      },
                      size: 36,
                      color: switch (c.status) {
                        ClassStatus.active => Colors.green,
                        ClassStatus.preparing => Colors.orange,
                        ClassStatus.ended => Colors.grey,
                      },
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('引用：${c.refName}'),
                        Text('${c.startDate} - ${c.endDate}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip(status: c.status),
                        const SizedBox(height: 2),
                        Text('👤 ${c.studentCount}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: c.progress,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassDetailScreen(classTeaching: c),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ClassDetailScreen extends StatelessWidget {
  final ClassTeaching classTeaching;

  const ClassDetailScreen({super.key, required this.classTeaching});

  @override
  Widget build(BuildContext context) {
    final courseDataService = context.watch<CourseDataService>();
    final students = courseDataService.getStudentsByClass(classTeaching.id);
    final teachers = courseDataService.getTeachersByClass(classTeaching.id);

    return Scaffold(
      appBar: AppBar(title: Text(classTeaching.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 班级信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(classTeaching.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      StatusChip(status: classTeaching.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow('引用', classTeaching.refName),
                  _infoRow('学段', '${classTeaching.startDate} - ${classTeaching.endDate}'),
                  _infoRow('学员数', '${classTeaching.studentCount}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: classTeaching.progress),
                  const SizedBox(height: 4),
                  Text('进度 ${(classTeaching.progress * 100).toInt()}%',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 教师配置入口
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('授课教师',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (teachers.isEmpty)
                    Text('暂无教师', style: TextStyle(color: Colors.grey[500]))
                  else
                    ...teachers.map((t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(t.name.isNotEmpty
                                ? t.name[0]
                                : '?'),
                          ),
                          title: Text(t.name),
                          subtitle: Text(t.title ?? t.email),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 学生列表
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('学员列表 (${students.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (students.isEmpty)
                    Text('暂无学员', style: TextStyle(color: Colors.grey[500]))
                  else
                    ...students.map((s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(s.name.isNotEmpty ? s.name[0] : '?'),
                          ),
                          title: Text(s.name),
                          subtitle: Text(s.email),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 考核管理入口
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssessmentListScreen(
                      classId: classTeaching.id,
                      className: classTeaching.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text('考核管理'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
