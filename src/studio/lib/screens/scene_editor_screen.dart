import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../models/scene.dart';
import '../services/program_service.dart';

class _MutableChoice {
  String label;
  String targetSceneId;

  _MutableChoice({required this.label, required this.targetSceneId});
}

/// 场景编辑器页面。
///
/// 在一个课时内创建/编辑/删除/排序场景和步骤。
class SceneEditorScreen extends StatefulWidget {
  final Lesson lesson;
  final String programId;
  final String courseId;
  final String phaseId;

  const SceneEditorScreen({
    super.key,
    required this.lesson,
    required this.programId,
    required this.courseId,
    required this.phaseId,
  });

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late List<Scene> _scenes;

  @override
  void initState() {
    super.initState();
    _scenes = List.from(widget.lesson.scenes);
  }

  ProgramService get _service => context.read<ProgramService>();

  String get _lessonId => widget.lesson.id;

  void _addScene() {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建场景'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '标识（name）', hintText: 'scene-1'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: '标题（title）', hintText: '场景一'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.isNotEmpty ? nameCtrl.text : 'scene-${DateTime.now().millisecondsSinceEpoch}';
              final title = titleCtrl.text.isNotEmpty ? titleCtrl.text : name;
              final scene = _service.createScene(_lessonId, name: name, title: title);
              setState(() => _scenes.add(scene));
              Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _editScene(Scene scene) {
    final nameCtrl = TextEditingController(text: scene.name);
    final titleCtrl = TextEditingController(text: scene.title);
    final verifyCtrl = TextEditingController(text: scene.verifyTip);
    final videoCtrl = TextEditingController(text: scene.videoUrl);
    final mutableChoices = scene.choices
        .map((c) => _MutableChoice(label: c.label, targetSceneId: c.targetSceneId))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑场景'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '标识（name）')),
                  const SizedBox(height: 8),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题（title）')),
                  const SizedBox(height: 8),
                  TextField(controller: verifyCtrl, decoration: const InputDecoration(labelText: '验证提示（verifyTip）'), maxLines: 2),
                  const SizedBox(height: 8),
                  TextField(controller: videoCtrl, decoration: const InputDecoration(labelText: '视频 URL'), maxLines: 1),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.alt_route, size: 18, color: Colors.purple),
                      const SizedBox(width: 6),
                      const Text('分支选项', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('添加分支', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showAddChoiceDialog(
                          ctx, setDialogState, mutableChoices,
                        ),
                      ),
                    ],
                  ),
                  if (mutableChoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('无分支选项，学员将直接完成课时',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    )
                  else
                    ...mutableChoices.asMap().entries.map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.purple,
                          ),
                          child: Center(
                            child: Text('${entry.key + 1}',
                                style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ),
                        ),
                        title: Text(entry.value.label, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('→ ${entry.value.targetSceneId}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              onPressed: () => _showEditChoiceDialog(
                                ctx, setDialogState, mutableChoices, entry.key,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              onPressed: () {
                                setDialogState(() => mutableChoices.removeAt(entry.key));
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                _service.updateScene(
                  _lessonId, scene.id,
                  name: nameCtrl.text,
                  title: titleCtrl.text,
                  verifyTip: verifyCtrl.text,
                  videoUrl: videoCtrl.text,
                  choices: mutableChoices
                      .map((c) => Choice(label: c.label, targetSceneId: c.targetSceneId))
                      .toList(),
                );
                setState(() {
                  final i = _scenes.indexWhere((s) => s.id == scene.id);
                  if (i != -1) {
                    _scenes[i] = _scenes[i].copyWith(
                      name: nameCtrl.text,
                      title: titleCtrl.text,
                      verifyTip: verifyCtrl.text,
                      videoUrl: videoCtrl.text,
                      choices: mutableChoices
                          .map((c) => Choice(label: c.label, targetSceneId: c.targetSceneId))
                          .toList(),
                    );
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChoiceDialog(
    BuildContext dialogContext,
    void Function(VoidCallback) setDialogState,
    List<_MutableChoice> mutableChoices,
  ) {
    final labelCtrl = TextEditingController();
    String selectedTargetId = _scenes.firstOrNull?.id ?? '';
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('添加分支'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '按钮文字', hintText: '继续'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedTargetId,
              decoration: const InputDecoration(labelText: '跳转目标场景'),
              items: _scenes
                  .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.title.isNotEmpty ? s.title : s.name, style: const TextStyle(fontSize: 13)),
                  ))
                  .toList(),
              onChanged: (v) => selectedTargetId = v ?? selectedTargetId,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (labelCtrl.text.isNotEmpty) {
                setDialogState(() {
                  mutableChoices.add(_MutableChoice(
                    label: labelCtrl.text,
                    targetSceneId: selectedTargetId,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditChoiceDialog(
    BuildContext dialogContext,
    void Function(VoidCallback) setDialogState,
    List<_MutableChoice> mutableChoices,
    int index,
  ) {
    final existing = mutableChoices[index];
    final labelCtrl = TextEditingController(text: existing.label);
    String selectedTargetId = existing.targetSceneId;
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑分支'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '按钮文字'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedTargetId,
              decoration: const InputDecoration(labelText: '跳转目标场景'),
              items: _scenes
                  .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.title.isNotEmpty ? s.title : s.name, style: const TextStyle(fontSize: 13)),
                  ))
                  .toList(),
              onChanged: (v) => selectedTargetId = v ?? selectedTargetId,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (labelCtrl.text.isNotEmpty) {
                setDialogState(() {
                  mutableChoices[index] = _MutableChoice(
                    label: labelCtrl.text,
                    targetSceneId: selectedTargetId,
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteScene(Scene scene) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除场景'),
        content: Text('确认删除「${scene.title}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _service.deleteScene(_lessonId, scene.id);
              setState(() => _scenes.removeWhere((s) => s.id == scene.id));
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ── Step operations ──

  void _addStep(Scene scene) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建步骤'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '步骤内容'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                _service.createStep(_lessonId, scene.id, ctrl.text);
                setState(() {
                  final i = _scenes.indexWhere((s) => s.id == scene.id);
                  if (i != -1) {
                    _scenes[i] = _scenes[i].copyWith(
                      steps: [
                        ..._scenes[i].steps,
                        Step(order: _scenes[i].steps.length, content: ctrl.text),
                      ],
                    );
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _editStep(Scene scene, int stepIndex) {
    final step = scene.steps[stepIndex];
    final ctrl = TextEditingController(text: step.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑步骤'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '步骤内容'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                _service.updateStep(_lessonId, scene.id, stepIndex, content: ctrl.text);
                setState(() {
                  final i = _scenes.indexWhere((s) => s.id == scene.id);
                  if (i != -1) {
                    final steps = [..._scenes[i].steps];
                    steps[stepIndex] = Step(order: stepIndex, content: ctrl.text);
                    _scenes[i] = _scenes[i].copyWith(steps: steps);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteStep(Scene scene, int stepIndex) {
    _service.deleteStep(_lessonId, scene.id, stepIndex);
    setState(() {
      final i = _scenes.indexWhere((s) => s.id == scene.id);
      if (i != -1) {
        final steps = [..._scenes[i].steps];
        steps.removeAt(stepIndex);
        final reindexed = steps.asMap().entries.map((e) => Step(order: e.key, content: e.value.content)).toList();
        _scenes[i] = _scenes[i].copyWith(steps: reindexed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑场景 — ${widget.lesson.title}'),
      ),
      body: _scenes.isEmpty
          ? const Center(child: Text('暂无场景，点击右下角 + 添加'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scenes.length,
              onReorder: (oldIndex, newIndex) {
                final adjustedNew = oldIndex < newIndex ? newIndex - 1 : newIndex;
                _service.reorderScenes(_lessonId, oldIndex, adjustedNew);
                setState(() {
                  final s = _scenes.removeAt(oldIndex);
                  _scenes.insert(adjustedNew, s);
                });
              },
              proxyDecorator: (child, index, animation) => Material(elevation: 2, child: child),
              itemBuilder: (_, i) => _buildSceneCard(_scenes[i]),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_scene',
        onPressed: _addScene,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSceneCard(Scene scene) {
    return Card(
      key: ValueKey(scene.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.play_circle_outline, color: Colors.purple),
            title: Text(scene.title.isNotEmpty ? scene.title : scene.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${scene.steps.length} 步', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: '编辑场景属性',
                  onPressed: () => _editScene(scene),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: '删除场景',
                  onPressed: () => _deleteScene(scene),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  tooltip: '添加步骤',
                  onPressed: () => _addStep(scene),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (scene.steps.isNotEmpty)
            ...scene.steps.asMap().entries.map((entry) => _buildStepTile(scene, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildStepTile(Scene scene, int index, Step step) {
    return Container(
      padding: const EdgeInsets.only(left: 56, right: 8),
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
              child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            title: Text(step.content, style: const TextStyle(fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () => _editStep(scene, index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  onPressed: () => _deleteStep(scene, index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
