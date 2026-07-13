import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../models/phase.dart';
import '../models/scene.dart';
import '../services/data_service.dart';
import 'preview_screen.dart';

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
          if (_expanded) ..._buildCourses(program.courses),
        ],
      ),
    );
  }

  List<Widget> _buildCourses(List<Course> courses) {
    if (courses.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 72, bottom: 16),
          child: Text('暂无课程', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return courses.map((c) => _CourseTile(course: c)).toList();
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

  int get _lessonCount =>
      widget.course.phases.fold(0, (s, p) => s + p.lessons.length);

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
                Text('$_lessonCount 课时',
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
          if (_expanded) ..._buildPhases(course.phases),
        ],
      ),
    );
  }

  List<Widget> _buildPhases(List<Phase> phases) {
    if (phases.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('暂无阶段', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return phases.map((p) => _PhaseTile(phase: p)).toList();
  }
}

class _PhaseTile extends StatefulWidget {
  final Phase phase;

  const _PhaseTile({required this.phase});

  @override
  State<_PhaseTile> createState() => _PhaseTileState();
}

class _PhaseTileState extends State<_PhaseTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    return Container(
      padding: const EdgeInsets.only(left: 56),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.layers, size: 18, color: Colors.teal),
            title: Text(phase.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text('${phase.lessons.length} 课时',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ),
          if (_expanded) ..._buildLessons(phase.lessons),
        ],
      ),
    );
  }

  List<Widget> _buildLessons(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('暂无课时', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return lessons.map((l) => _LessonTile(lesson: l)).toList();
  }
}

class _LessonTile extends StatefulWidget {
  final Lesson lesson;

  const _LessonTile({required this.lesson});

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Container(
      padding: const EdgeInsets.only(left: 56),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.description, size: 18, color: Colors.orange),
            title: Text(lesson.title, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${lesson.duration}分钟',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(status: lesson.status.label),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.headphones, size: 18),
                  tooltip: '试听',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreviewScreen(lessonId: lesson.id),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildScenes(lesson.scenes),
        ],
      ),
    );
  }

  List<Widget> _buildScenes(List<Scene> scenes) {
    if (scenes.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('暂无场景', style: TextStyle(color: Colors.grey)),
        )
      ];
    }
    return scenes.map((s) => _SceneTile(scene: s)).toList();
  }
}

class _SceneTile extends StatefulWidget {
  final Scene scene;

  const _SceneTile({required this.scene});

  @override
  State<_SceneTile> createState() => _SceneTileState();
}

class _SceneTileState extends State<_SceneTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    return Container(
      padding: const EdgeInsets.only(left: 56),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.play_circle_outline, size: 16, color: Colors.purple),
            title: Text(scene.title, style: const TextStyle(fontSize: 13)),
            subtitle: scene.verifyTip.isNotEmpty
                ? Text(scene.verifyTip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${scene.steps.length} 步',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildSteps(scene.steps),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(List<Step> steps) {
    return steps
        .map((s) => Container(
              padding: const EdgeInsets.only(left: 72, right: 16, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: Text('${s.order}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.blue)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.content,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
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
