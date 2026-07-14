import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/program.dart';
import '../models/phase.dart';
import '../models/scene.dart';
import '../services/data_service.dart';
import '../widgets/status_chip.dart';
import 'preview_screen.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  void _showCreateProgramDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建专业'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                context.read<CourseDataService>().createProgram(
                      nameCtrl.text,
                      descCtrl.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showCreateCourseDialog(String programId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建课程'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                context.read<CourseDataService>().createCourse(
                      programId, nameCtrl.text, descCtrl.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showCreatePhaseDialog(String programId, String courseId) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建阶段'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                context.read<CourseDataService>().createPhase(
                      programId, courseId, nameCtrl.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showCreateLessonDialog(String programId, String courseId, String phaseId) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建课时'),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '标题'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                context.read<CourseDataService>().createLesson(
                      programId, courseId, phaseId, titleCtrl.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _rename(CourseDataService service, String type, List<String> ids, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑$type名称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty && ctrl.text != current) {
                switch (type) {
                  case '专业':
                    service.updateProgram(ids[0], name: ctrl.text);
                  case '课程':
                    service.updateCourse(ids[0], ids[1], name: ctrl.text);
                  case '阶段':
                    service.updatePhase(ids[0], ids[1], ids[2], name: ctrl.text);
                  case '课时':
                    service.updateLesson(ids[0], ids[1], ids[2], ids[3], title: ctrl.text);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CourseDataService service, String type, List<String> ids, int childCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除$type'),
        content: Text(childCount > 0
            ? '该$type包含 $childCount 个子项，确认删除？'
            : '确认删除该$type？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              switch (type) {
                case '专业':
                  service.deleteProgram(ids[0]);
                case '课程':
                  service.deleteCourse(ids[0], ids[1]);
                case '阶段':
                  service.deletePhase(ids[0], ids[1], ids[2]);
                case '课时':
                  service.deleteLesson(ids[0], ids[1], ids[2], ids[3]);
              }
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

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
                  _ProgramTile(
                    service: service,
                    program: service.programs[i],
                    parent: this,
                  ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_program',
        onPressed: _showCreateProgramDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProgramTile extends StatefulWidget {
  final CourseDataService service;
  final Program program;
  final _ProgramScreenState parent;

  const _ProgramTile({
    required this.service,
    required this.program,
    required this.parent,
  });

  @override
  State<_ProgramTile> createState() => _ProgramTileState();
}

class _ProgramTileState extends State<_ProgramTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final canDelete = program.status != ContentStatus.published;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder, size: 32, color: Colors.blue),
            title: InkWell(
              onTap: () => widget.parent._rename(
                widget.service, '专业', [program.id], program.name,
              ),
              child: Text(program.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            subtitle: Text(program.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(status: program.status),
                const SizedBox(width: 8),
                Text('${program.courses.length} 门',
                    style: TextStyle(color: Colors.grey[500])),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.parent._confirmDelete(
                      widget.service, '专业', [program.id], program.courses.length,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildCourses(program.courses, program.id),
        ],
      ),
    );
  }

  List<Widget> _buildCourses(List<Course> courses, String programId) {
    final tiles = <Widget>[
      for (final c in courses)
        _CourseTile(
          service: widget.service,
          course: c,
          programId: programId,
          parent: widget.parent,
        ),
    ];
    tiles.add(
      Padding(
        padding: const EdgeInsets.only(left: 56, top: 4, bottom: 4),
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('新建课程'),
          onPressed: () => widget.parent._showCreateCourseDialog(programId),
        ),
      ),
    );
    return tiles;
  }
}

class _CourseTile extends StatefulWidget {
  final CourseDataService service;
  final Course course;
  final String programId;
  final _ProgramScreenState parent;

  const _CourseTile({
    required this.service,
    required this.course,
    required this.programId,
    required this.parent,
  });

  @override
  State<_CourseTile> createState() => _CourseTileState();
}

class _CourseTileState extends State<_CourseTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final canDelete = course.status != ContentStatus.published;
    return Container(
      padding: const EdgeInsets.only(left: 56, right: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.book, size: 20, color: Colors.green),
            title: InkWell(
              onTap: () => widget.parent._rename(
                widget.service, '课程', [widget.programId, course.id], course.name,
              ),
              child: Text(course.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            subtitle: Text(course.description,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(status: course.status),
                const SizedBox(width: 8),
                Text('$_lessonCount 课时',
                    style: TextStyle(color: Colors.grey[500])),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.parent._confirmDelete(
                      widget.service, '课程', [widget.programId, course.id],
                      course.phases.fold(0, (s, p) => s + p.lessons.length),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildPhases(course.phases, widget.programId, course.id),
        ],
      ),
    );
  }

  int get _lessonCount =>
      widget.course.phases.fold(0, (s, p) => s + p.lessons.length);

  List<Widget> _buildPhases(List<Phase> phases, String programId, String courseId) {
    final tiles = <Widget>[
      for (final p in phases)
        _PhaseTile(
          service: widget.service,
          phase: p,
          programId: programId,
          courseId: courseId,
          parent: widget.parent,
        ),
    ];
    tiles.add(
      Padding(
        padding: const EdgeInsets.only(left: 56, top: 2, bottom: 2),
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 14),
          label: const Text('新建阶段', style: TextStyle(fontSize: 13)),
          onPressed: () => widget.parent._showCreatePhaseDialog(programId, courseId),
        ),
      ),
    );
    return tiles;
  }
}

class _PhaseTile extends StatefulWidget {
  final CourseDataService service;
  final Phase phase;
  final String programId;
  final String courseId;
  final _ProgramScreenState parent;

  const _PhaseTile({
    required this.service,
    required this.phase,
    required this.programId,
    required this.courseId,
    required this.parent,
  });

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
            title: InkWell(
              onTap: () => widget.parent._rename(
                widget.service, '阶段', [widget.programId, widget.courseId, phase.id], phase.name,
              ),
              child: Text(phase.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            subtitle: Text('${phase.lessons.length} 课时',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(status: phase.status),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () => widget.parent._confirmDelete(
                    widget.service, '阶段', [widget.programId, widget.courseId, phase.id],
                    phase.lessons.length,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_expanded) ..._buildLessons(phase.lessons, widget.programId, widget.courseId, phase.id),
        ],
      ),
    );
  }

  List<Widget> _buildLessons(List<Lesson> lessons, String programId, String courseId, String phaseId) {
    final tiles = <Widget>[
      for (final l in lessons)
        _LessonTile(
          service: widget.service,
          lesson: l,
          programId: programId,
          courseId: courseId,
          phaseId: phaseId,
          parent: widget.parent,
        ),
    ];
    tiles.add(
      Padding(
        padding: const EdgeInsets.only(left: 56, top: 2, bottom: 2),
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 14),
          label: const Text('新建课时', style: TextStyle(fontSize: 13)),
          onPressed: () => widget.parent._showCreateLessonDialog(programId, courseId, phaseId),
        ),
      ),
    );
    return tiles;
  }
}

class _LessonTile extends StatefulWidget {
  final CourseDataService service;
  final Lesson lesson;
  final String programId;
  final String courseId;
  final String phaseId;
  final _ProgramScreenState parent;

  const _LessonTile({
    required this.service,
    required this.lesson,
    required this.programId,
    required this.courseId,
    required this.phaseId,
    required this.parent,
  });

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final canDelete = lesson.status != ContentStatus.published;
    return Container(
      padding: const EdgeInsets.only(left: 56),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.description, size: 18, color: Colors.orange),
            title: InkWell(
              onTap: () => widget.parent._rename(
                widget.service, '课时', [widget.programId, widget.courseId, widget.phaseId, lesson.id], lesson.title,
              ),
              child: Text(lesson.title, style: const TextStyle(fontSize: 14)),
            ),
            subtitle: Text('${lesson.duration}分钟',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(status: lesson.status),
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => widget.parent._confirmDelete(
                      widget.service, '课时', [widget.programId, widget.courseId, widget.phaseId, lesson.id],
                      lesson.scenes.length,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
