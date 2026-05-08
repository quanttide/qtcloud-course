import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../services/data_service.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourseDataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('课程研发')),
      body: service.programs.isEmpty
          ? const Center(child: Text('暂无数据'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.programs.length,
              itemBuilder: (_, i) =>
                  _ProgramTile(program: service.programs[i]),
            ),
    );
  }
}

class _ProgramTile extends StatefulWidget {
  final Program program;

  const _ProgramTile({required this.program});

  @override
  State<_ProgramTile> createState() => _ProgramTileState();
}

class _ProgramTileState extends State<_ProgramTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder, size: 32, color: Colors.blue),
            title: Text(program.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(program.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(status: program.status.label),
                const SizedBox(width: 8),
                Text('${program.courses.length} 门',
                    style: TextStyle(color: Colors.grey[500])),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildCourses(context, program.courses),
        ],
      ),
    );
  }

  List<Widget> _buildCourses(BuildContext context, List<Course> courses) {
    if (courses.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 72, bottom: 16),
          child: Text('暂无课程', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return courses
        .map((c) => _CourseTile(course: c))
        .toList();
  }
}

class _CourseTile extends StatefulWidget {
  final Course course;

  const _CourseTile({required this.course});

  @override
  State<_CourseTile> createState() => _CourseTileState();
}

class _CourseTileState extends State<_CourseTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Container(
      padding: const EdgeInsets.only(left: 56, right: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.book, size: 20, color: Colors.green),
            title: Text(course.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(course.description,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(status: course.status.label),
                const SizedBox(width: 8),
                Text('${course.lessons.length} 课时',
                    style: TextStyle(color: Colors.grey[500])),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildLessons(context, course.lessons),
        ],
      ),
    );
  }

  List<Widget> _buildLessons(BuildContext context, List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('暂无课时', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return lessons
        .map((l) => Container(
              padding: const EdgeInsets.only(left: 56),
              child: ListTile(
                dense: true,
                leading:
                    const Icon(Icons.description, size: 18, color: Colors.orange),
                title: Text(l.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text('${l.duration}分钟',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                trailing: _StatusChip(status: l.status.label),
              ),
            ))
        .toList();
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '已发布' => Colors.green,
      '草稿' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
