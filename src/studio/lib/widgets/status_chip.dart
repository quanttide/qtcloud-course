import 'package:flutter/material.dart';
import '../models/enums.dart';

/// 通用状态标签组件，接受 [ContentStatus] 或 [ClassStatus]。
class StatusChip extends StatelessWidget {
  final Object status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final label = _resolveLabel();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  Color _resolveColor() {
    if (status is ContentStatus) {
      return switch (status as ContentStatus) {
        ContentStatus.draft => Colors.orange,
        ContentStatus.published => Colors.green,
      };
    }
    return Colors.grey;
  }

  String _resolveLabel() {
    if (status is ContentStatus) {
      return (status as ContentStatus).label;
    }
    return status.toString();
  }
}
