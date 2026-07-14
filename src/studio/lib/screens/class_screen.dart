import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../models/enums.dart';
import '../widgets/status_chip.dart';

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
                        Text('👥 ${c.studentCount}',
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
                    onTap: () => _showClassDetail(context, c),
                  ),
                );
              },
            ),
    );
  }

  void _showClassDetail(BuildContext context, dynamic classTeaching) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(classTeaching.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DetailCard(
                      label: '学员数', value: '${classTeaching.studentCount}'),
                  const SizedBox(width: 12),
                  _DetailCard(label: '出勤率', value: '92%'),
                  const SizedBox(width: 12),
                  _DetailCard(label: '完成率',
                      value: '${(classTeaching.progress * 100).toInt()}%'),
                ],
              ),
              const SizedBox(height: 24),
              Text('班级信息',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _InfoRow(label: '引用内容', value: classTeaching.refName),
              _InfoRow(label: '教学周期', value:
                  '${classTeaching.startDate} - ${classTeaching.endDate}'),
              _InfoRow(label: '状态', value: classTeaching.status.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;

  const _DetailCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value),
        ],
      ),
    );
  }
}
