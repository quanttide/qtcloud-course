import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/program.dart';
import '../models/phase.dart';
import '../models/scene.dart';
import '../services/program_service.dart';
import '../widgets/status_chip.dart';
import 'preview_screen.dart';
import 'scene_editor_screen.dart';

enum _NodeType { program, course, phase, lesson }

class _FlatNode {
  final _NodeType type;
  final dynamic data;
  final int depth;
  final List<String> ids;

  const _FlatNode({
    required this.type,
    required this.data,
    required this.depth,
    required this.ids,
  });

  String get id => ids.last;
}

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final Set<String> _expandedIds = {};

  List<_FlatNode> _buildFlatList(ProgramService service) {
    final nodes = <_FlatNode>[];
    for (final p in service.programs) {
      nodes.add(
        _FlatNode(type: _NodeType.program, data: p, depth: 0, ids: [p.id]),
      );
      if (_expandedIds.contains(p.id)) {
        for (final c in p.courses) {
          nodes.add(
            _FlatNode(
              type: _NodeType.course,
              data: c,
              depth: 1,
              ids: [p.id, c.id],
            ),
          );
          if (_expandedIds.contains(c.id)) {
            for (final ph in c.phases) {
              nodes.add(
                _FlatNode(
                  type: _NodeType.phase,
                  data: ph,
                  depth: 2,
                  ids: [p.id, c.id, ph.id],
                ),
              );
              if (_expandedIds.contains(ph.id)) {
                for (final l in ph.lessons) {
                  nodes.add(
                    _FlatNode(
                      type: _NodeType.lesson,
                      data: l,
                      depth: 3,
                      ids: [p.id, c.id, ph.id, l.id],
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }
    return nodes;
  }

  bool _hasChildren(_FlatNode node, ProgramService service) {
    switch (node.type) {
      case _NodeType.program:
        return (node.data as Program).courses.isNotEmpty;
      case _NodeType.course:
        return (node.data as Course).phases.isNotEmpty;
      case _NodeType.phase:
        return (node.data as Phase).lessons.isNotEmpty;
      case _NodeType.lesson:
        return false;
    }
  }

  void _onReorder(int oldIndex, int newIndex, List<_FlatNode> nodes) {
    if (oldIndex == newIndex) return;
    final node = nodes[oldIndex];
    final adjustedNew = oldIndex < newIndex ? newIndex - 1 : newIndex;

    final targetNode = adjustedNew < nodes.length ? nodes[adjustedNew] : null;
    final targetBefore = adjustedNew > 0 ? nodes[adjustedNew - 1] : null;
    if ((targetNode == null || targetNode.type != node.type) &&
        (targetBefore == null || targetBefore.type != node.type)) {
      return;
    }

    if (node.type == _NodeType.course) {
      final parentId = node.ids[0];
      if ((targetNode != null &&
              targetNode.type == _NodeType.course &&
              targetNode.ids[0] != parentId) ||
          (targetBefore != null &&
              targetBefore.type == _NodeType.course &&
              targetBefore.ids[0] != parentId)) {
        return;
      }
    }
    if (node.type == _NodeType.phase) {
      final parentId = node.ids[0];
      final parentId2 = node.ids[1];
      if ((targetNode != null &&
              targetNode.type == _NodeType.phase &&
              (targetNode.ids[0] != parentId ||
                  targetNode.ids[1] != parentId2)) ||
          (targetBefore != null &&
              targetBefore.type == _NodeType.phase &&
              (targetBefore.ids[0] != parentId ||
                  targetBefore.ids[1] != parentId2))) {
        return;
      }
    }
    if (node.type == _NodeType.lesson) {
      final parentId = node.ids[0];
      final parentId2 = node.ids[1];
      final parentId3 = node.ids[2];
      if ((targetNode != null &&
              targetNode.type == _NodeType.lesson &&
              (targetNode.ids[0] != parentId ||
                  targetNode.ids[1] != parentId2 ||
                  targetNode.ids[2] != parentId3)) ||
          (targetBefore != null &&
              targetBefore.type == _NodeType.lesson &&
              (targetBefore.ids[0] != parentId ||
                  targetBefore.ids[1] != parentId2 ||
                  targetBefore.ids[2] != parentId3))) {
        return;
      }
    }

    final service = context.read<ProgramService>();
    List<_FlatNode> siblings;
    switch (node.type) {
      case _NodeType.program:
        siblings = nodes.where((n) => n.type == _NodeType.program).toList();
      case _NodeType.course:
        siblings = nodes
            .where((n) => n.type == _NodeType.course && n.ids[0] == node.ids[0])
            .toList();
      case _NodeType.phase:
        siblings = nodes
            .where(
              (n) =>
                  n.type == _NodeType.phase &&
                  n.ids[0] == node.ids[0] &&
                  n.ids[1] == node.ids[1],
            )
            .toList();
      case _NodeType.lesson:
        siblings = nodes
            .where(
              (n) =>
                  n.type == _NodeType.lesson &&
                  n.ids[0] == node.ids[0] &&
                  n.ids[1] == node.ids[1] &&
                  n.ids[2] == node.ids[2],
            )
            .toList();
    }

    final oldSiblingIndex = siblings.indexWhere((n) => n.id == node.id);
    final nodesBeforeNew = nodes.take(adjustedNew);
    final siblingsBeforeNew = nodesBeforeNew
        .where((n) => siblings.any((s) => s.id == n.id))
        .length;

    switch (node.type) {
      case _NodeType.program:
        service.reorderProgram(oldSiblingIndex, siblingsBeforeNew);
      case _NodeType.course:
        service.reorderCourses(node.ids[0], oldSiblingIndex, siblingsBeforeNew);
      case _NodeType.phase:
        service.reorderPhases(
          node.ids[0],
          node.ids[1],
          oldSiblingIndex,
          siblingsBeforeNew,
        );
      case _NodeType.lesson:
        service.reorderLessons(
          node.ids[0],
          node.ids[1],
          node.ids[2],
          oldSiblingIndex,
          siblingsBeforeNew,
        );
    }
  }

  // ── Dialog methods ──

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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                context.read<ProgramService>().createProgram(
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

  String _nodeTypeLabel(_NodeType t) => switch (t) {
    _NodeType.program => '专业',
    _NodeType.course => '课程',
    _NodeType.phase => '阶段',
    _NodeType.lesson => '课时',
  };

  void _rename(
    ProgramService service,
    _NodeType type,
    List<String> ids,
    String current,
  ) {
    final ctrl = TextEditingController(text: current);
    final label = _nodeTypeLabel(type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑$label名称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty && ctrl.text != current) {
                switch (type) {
                  case _NodeType.program:
                    service.updateProgram(ids[0], name: ctrl.text);
                  case _NodeType.course:
                    service.updateCourse(ids[0], ids[1], name: ctrl.text);
                  case _NodeType.phase:
                    service.updatePhase(
                      ids[0],
                      ids[1],
                      ids[2],
                      name: ctrl.text,
                    );
                  case _NodeType.lesson:
                    service.updateLesson(
                      ids[0],
                      ids[1],
                      ids[2],
                      ids[3],
                      title: ctrl.text,
                    );
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

  void _confirmDelete(
    ProgramService service,
    _NodeType type,
    List<String> ids,
    int childCount,
  ) {
    final label = _nodeTypeLabel(type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除$label'),
        content: Text(
          childCount > 0 ? '该$label包含 $childCount 个子项，确认删除？' : '确认删除该$label？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              switch (type) {
                case _NodeType.program:
                  service.deleteProgram(ids[0]);
                case _NodeType.course:
                  service.deleteCourse(ids[0], ids[1]);
                case _NodeType.phase:
                  service.deletePhase(ids[0], ids[1], ids[2]);
                case _NodeType.lesson:
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

  Future<bool> _confirmPublishWithDrafts(String label, int draftCount) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('发布$label'),
            content: Text(
              '该$label包含 $draftCount 个草稿课时，确认发布？\n\n学员将能看到已发布的课时，草稿课时暂不可见。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确认发布'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _togglePublish(
    ProgramService service,
    _NodeType type,
    List<String> ids,
  ) async {
    switch (type) {
      case _NodeType.program:
        final p = service.programs.firstWhere((p) => p.id == ids[0]);
        if (p.status == ContentStatus.draft) {
          service.publishProgram(ids[0]);
        } else {
          service.unpublishProgram(ids[0]);
        }
      case _NodeType.course:
        final p = service.programs.firstWhere((p) => p.id == ids[0]);
        final c = p.courses.firstWhere((c) => c.id == ids[1]);
        if (c.status == ContentStatus.draft) {
          final draftCount = service.draftLessonCountInCourse(ids[0], ids[1]);
          if (draftCount > 0) {
            final confirmed = await _confirmPublishWithDrafts('课程', draftCount);
            if (!confirmed) return;
          }
          service.publishCourse(ids[0], ids[1]);
        } else {
          service.unpublishCourse(ids[0], ids[1]);
        }
      case _NodeType.lesson:
        final p = service.programs.firstWhere((p) => p.id == ids[0]);
        final c = p.courses.firstWhere((c) => c.id == ids[1]);
        final ph = c.phases.firstWhere((ph) => ph.id == ids[2]);
        final l = ph.lessons.firstWhere((l) => l.id == ids[3]);
        if (l.status == ContentStatus.draft) {
          service.publishLesson(ids[0], ids[1], ids[2], ids[3]);
        } else {
          service.unpublishLesson(ids[0], ids[1], ids[2], ids[3]);
        }
      case _NodeType.phase:
        break;
    }
  }

  Future<void> _exportPrograms() async {
    final service = context.read<ProgramService>();
    final ok = await service.exportProgramsToFile();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? '导出成功' : '导出已取消')));
  }

  Future<void> _importPrograms() async {
    final service = context.read<ProgramService>();
    final jsonStr = await service.importProgramsFromFile();
    if (jsonStr == null) return;
    final ok = service.mergeProgramsFromJson(jsonStr);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? '导入成功' : '导入失败：JSON 格式错误')));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProgramService>();
    final nodes = _buildFlatList(service);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程研发'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: '导入',
            onPressed: _importPrograms,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出',
            onPressed: _exportPrograms,
          ),
        ],
      ),
      body: nodes.isEmpty
          ? const Center(child: Text('暂无数据'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: nodes.length,
              onReorder: (oldIndex, newIndex) =>
                  _onReorder(oldIndex, newIndex, nodes),
              proxyDecorator: (child, index, animation) =>
                  Material(elevation: 2, child: child),
              itemBuilder: (_, i) => _buildTile(service, nodes[i], i),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_program',
        onPressed: _showCreateProgramDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTile(ProgramService service, _FlatNode node, int index) {
    final expanded = _expandedIds.contains(node.id);
    final hasChildren = _hasChildren(node, service);

    Widget titleWidget;
    String? subtitleText;
    Widget? leadingIcon;
    List<Widget> actions = [];

    switch (node.type) {
      case _NodeType.program:
        final p = node.data as Program;
        leadingIcon = const Icon(Icons.folder, size: 24, color: Colors.blue);
        subtitleText = p.description;
        actions = [
          StatusChip(status: p.status),
          const SizedBox(width: 4),
          Text(
            '${p.courses.length} 门',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          IconButton(
            icon: Icon(
              p.status == ContentStatus.draft
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_download_outlined,
              size: 18,
              color: p.status == ContentStatus.draft
                  ? Colors.green
                  : Colors.orange,
            ),
            tooltip: p.status == ContentStatus.draft ? '发布' : '下架',
            onPressed: () => _togglePublish(service, _NodeType.program, [p.id]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (p.status != ContentStatus.published)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(service, _NodeType.program, [
                p.id,
              ], p.courses.length),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (hasChildren)
            IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _toggleExpanded(node.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ];
        titleWidget = InkWell(
          onTap: () => _rename(service, _NodeType.program, [p.id], p.name),
          child: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

      case _NodeType.course:
        final c = node.data as Course;
        leadingIcon = const Icon(Icons.book, size: 20, color: Colors.green);
        subtitleText = c.description;
        final lessonCount = c.phases.fold(
          0,
          (sum, ph) => sum + ph.lessons.length,
        );
        actions = [
          StatusChip(status: c.status),
          const SizedBox(width: 4),
          Text(
            '$lessonCount 课时',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          IconButton(
            icon: Icon(
              c.status == ContentStatus.draft
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_download_outlined,
              size: 18,
              color: c.status == ContentStatus.draft
                  ? Colors.green
                  : Colors.orange,
            ),
            tooltip: c.status == ContentStatus.draft ? '发布' : '下架',
            onPressed: () =>
                _togglePublish(service, _NodeType.course, [node.ids[0], c.id]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (c.status != ContentStatus.published)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(service, _NodeType.course, [
                node.ids[0],
                c.id,
              ], lessonCount),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (hasChildren)
            IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _toggleExpanded(node.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ];
        titleWidget = InkWell(
          onTap: () =>
              _rename(service, _NodeType.course, [node.ids[0], c.id], c.name),
          child: Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );

      case _NodeType.phase:
        final ph = node.data as Phase;
        leadingIcon = const Icon(Icons.layers, size: 18, color: Colors.teal);
        subtitleText = '${ph.lessons.length} 课时';
        actions = [
          StatusChip(status: ph.status),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => _confirmDelete(service, _NodeType.phase, [
              node.ids[0],
              node.ids[1],
              ph.id,
            ], ph.lessons.length),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (hasChildren)
            IconButton(
              icon: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              onPressed: () => setState(() => _toggleExpanded(node.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ];
        titleWidget = InkWell(
          onTap: () => _rename(service, _NodeType.phase, [
            node.ids[0],
            node.ids[1],
            ph.id,
          ], ph.name),
          child: Text(
            ph.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        );

      case _NodeType.lesson:
        final l = node.data as Lesson;
        leadingIcon = const Icon(
          Icons.description,
          size: 18,
          color: Colors.orange,
        );
        subtitleText = '${l.duration}分钟';
        actions = [
          StatusChip(status: l.status),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              l.status == ContentStatus.draft
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_download_outlined,
              size: 18,
              color: l.status == ContentStatus.draft
                  ? Colors.green
                  : Colors.orange,
            ),
            tooltip: l.status == ContentStatus.draft ? '发布' : '下架',
            onPressed: () => _togglePublish(service, _NodeType.lesson, [
              node.ids[0],
              node.ids[1],
              node.ids[2],
              l.id,
            ]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 18),
            tooltip: '编辑场景',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SceneEditorScreen(
                    lesson: l,
                    programId: node.ids[0],
                    courseId: node.ids[1],
                    phaseId: node.ids[2],
                  ),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.headphones, size: 18),
            tooltip: '试听',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(lessonId: l.id),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (l.status != ContentStatus.published)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => _confirmDelete(service, _NodeType.lesson, [
                node.ids[0],
                node.ids[1],
                node.ids[2],
                l.id,
              ], l.scenes.length),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (l.scenes.isNotEmpty)
            IconButton(
              icon: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              onPressed: () => setState(() => _toggleExpanded(node.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ];
        titleWidget = InkWell(
          onTap: () => _rename(service, _NodeType.lesson, [
            node.ids[0],
            node.ids[1],
            node.ids[2],
            l.id,
          ], l.title),
          child: Text(l.title, style: const TextStyle(fontSize: 14)),
        );
    }

    return Card(
      key: ValueKey(node.id),
      margin: EdgeInsets.only(left: node.depth * 24.0, bottom: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: leadingIcon,
            title: titleWidget,
            subtitle: subtitleText.isNotEmpty
                ? Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                : null,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
          if (expanded && node.type == _NodeType.lesson)
            ..._buildScenes((node.data as Lesson).scenes),
        ],
      ),
    );
  }

  void _toggleExpanded(String id) {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
  }

  List<Widget> _buildScenes(List<Scene> scenes) {
    if (scenes.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('暂无场景', style: TextStyle(color: Colors.grey)),
        ),
      ];
    }
    return scenes.map((s) => _buildSceneTile(s)).toList();
  }

  Widget _buildSceneTile(Scene scene) {
    return Container(
      padding: const EdgeInsets.only(left: 56, right: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.play_circle_outline,
              size: 16,
              color: Colors.purple,
            ),
            title: Text(scene.title, style: const TextStyle(fontSize: 13)),
            subtitle: scene.verifyTip.isNotEmpty
                ? Text(
                    scene.verifyTip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${scene.steps.length} 步',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
