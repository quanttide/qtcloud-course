/// 学员端形态的课时预览：结构与文案照 qtclass-lite 的 `LessonDetail.tsx` 渲染，
/// 只是换成 Flutter 控件。右侧看到的必须与学员在 lite 页面看到的逐字一致，
/// 否则预览就失去「发版前先对一遍」的意义。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lesson.dart';

class LessonPreview extends StatefulWidget {
  final Lesson lesson;

  const LessonPreview({super.key, required this.lesson});

  @override
  State<LessonPreview> createState() => _LessonPreviewState();
}

class _LessonPreviewState extends State<LessonPreview> {
  /// 刚复制过的文本；与 lite 的 CopyBox 同语义——每个复制块各自记状态
  String? _copiedText;
  Timer? _resetTimer;

  bool _copied(String text) => _copiedText == text;

  Future<void> _copy(String text) async {
    // 先给反馈，剪贴板失败也不吞掉按钮状态
    setState(() => _copiedText = text);
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      // 桌面/测试环境可能没有剪贴板服务，状态照常回退
    }
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedText = null);
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        // 页眉：kicker + 标题 + lede
        if (lesson.kicker != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              lesson.kicker!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          lesson.title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (lesson.lede != null) ...[
          const SizedBox(height: 8),
          Text(lesson.lede!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 20),

        for (final step in lesson.steps) ...[
          _StepView(
            step: step,
            isCopied: _copied,
            onCopy: _copy,
          ),
          const SizedBox(height: 20),
        ],

        if (lesson.tip != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(lesson.tip!),
          ),
          const SizedBox(height: 12),
        ],
        if (lesson.foot != null) ...[
          Text(
            lesson.foot!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '课时内容与教程仓同源，改动以教程仓为准。',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _StepView extends StatelessWidget {
  final LessonStep step;
  final bool Function(String text) isCopied;
  final ValueChanged<String> onCopy;

  const _StepView({required this.step, required this.isCopied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${step.num}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (step.doText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(step.doText, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final block in step.blocks) ...[
          _BlockView(block: block, isCopied: isCopied, onCopy: onCopy),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BlockView extends StatelessWidget {
  final LessonBlock block;
  final bool Function(String text) isCopied;
  final ValueChanged<String> onCopy;

  const _BlockView({required this.block, required this.isCopied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget labeled(String? label, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null && label.isNotEmpty) ...[
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],
            child,
          ],
        );

    switch (block) {
      case NoteBlock(:final label, :final lines):
        return labeled(
          label,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line, style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        );
      case CopyBlock(:final label, :final text):
        return labeled(
          label,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(text, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => onCopy(text),
                child: Text(isCopied(text) ? '已复制，去粘贴吧' : '复制这句话'),
              ),
            ],
          ),
        );
      case CodeBlock(:final label, :final lines):
        return labeled(
          label,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: line.ok ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        );
      case LinkBlock(:final label, :final url, :final tip):
        return labeled(
          label,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(url, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
              if (tip != null) ...[
                const SizedBox(height: 4),
                Text(tip, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        );
      case ImageBlock(:final label, :final src, :final alt, :final tip):
        return labeled(
          label,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  src,
                  errorBuilder: (_, _, _) => Container(
                    height: 140,
                    alignment: Alignment.center,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Text(alt, style: theme.textTheme.bodySmall),
                  ),
                ),
              ),
              if (tip != null) ...[
                const SizedBox(height: 4),
                Text(tip, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        );
    }
  }
}
