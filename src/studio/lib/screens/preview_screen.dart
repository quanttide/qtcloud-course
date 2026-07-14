import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../models/scene.dart';
import '../services/data_service.dart';

/// 试听预览页，全屏课堂页面。
///
/// 左侧视频占位 + 场景标题，右侧操作步骤面板。
/// 通过 [lessonId] 从 DataService 加载课时数据，
/// 或直接传入 [lesson] 对象（主要用于测试）。
class PreviewScreen extends StatefulWidget {
  final String lessonId;
  final Lesson? lesson;

  const PreviewScreen({super.key, required this.lessonId, this.lesson});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Lesson? _lesson;
  String _currentSceneId = '';
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _lesson = widget.lesson;
      _currentSceneId = _lesson!.scenes.firstOrNull?.id ?? '';
    } else {
      _loadLesson();
    }
  }

  Future<void> _loadLesson() async {
    final service = context.read<CourseDataService>();
    final lesson = await service.loadLesson(widget.lessonId);
    if (mounted) {
      setState(() {
        _lesson = lesson;
        _currentSceneId = lesson?.scenes.firstOrNull?.id ?? '';
      });
    }
  }

  Scene? get _currentScene {
    if (_lesson == null) return null;
    try {
      return _lesson!.scenes.firstWhere((s) => s.id == _currentSceneId);
    } catch (_) {
      return null;
    }
  }

  void _goToScene(String sceneId) {
    setState(() => _currentSceneId = sceneId);
  }

  void _finish() {
    setState(() => _completed = true);
  }

  void _handleChoice(String targetSceneId) {
    final target = _lesson!.scenes.any((s) => s.id == targetSceneId);
    if (target) {
      _goToScene(targetSceneId);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lesson?.title ?? '试听')),
      body: _lesson == null
          ? const Center(child: CircularProgressIndicator())
          : _completed
          ? _buildCompletionPage()
          : _buildLessonLayout(),
    );
  }

  Widget _buildCompletionPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '课时完成',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              '你已完成「${_lesson!.title}」的所有场景。',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonLayout() {
    final scene = _currentScene;
    if (scene == null) {
      return const Center(child: Text('未找到场景数据'));
    }

    return Row(
      children: [
        // 左侧：视频区域 + 场景标题
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scene.videoUrl.isNotEmpty
                                ? scene.videoUrl
                                : '视频播放区域',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Text(
                  scene.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 右侧：操作步骤面板
        SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: const Text(
                    '操作步骤',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // 场景导航
                SizedBox(
                  height: 44 * _lesson!.scenes.length.toDouble(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _lesson!.scenes.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 44),
                    itemBuilder: (_, i) {
                      final s = _lesson!.scenes[i];
                      final isActive = s.id == _currentSceneId;
                      return InkWell(
                        onTap: () => _goToScene(s.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? Colors.blue
                                      : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isActive ? Colors.blue : null,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // 步骤列表
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      ...scene.steps.map((step) => _StepTile(step: step)),
                      const SizedBox(height: 12),

                      // 验证提示
                      if (scene.verifyTip.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✅ ', style: TextStyle(fontSize: 13)),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '验证：',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      TextSpan(text: scene.verifyTip),
                                    ],
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // 继续/完成按钮
                if (scene.choices.isNotEmpty)
                  ...scene.choices.map(
                    (c) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: FilledButton(
                        onPressed: () => _handleChoice(c.targetSceneId),
                        child: Text('${c.label} →'),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: _finish,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('完成课时 🎉'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final Step step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: Text(
              '${step.order}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                step.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
