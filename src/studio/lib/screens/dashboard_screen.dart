import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import 'program_screen.dart';
import 'class_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourseDataService>();
    final programs = service.programs;
    final classes = service.classes;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('仪表盘',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _MetricCard(
                  label: '专业数',
                  value: '${service.totalPrograms}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              _MetricCard(
                  label: '课程数',
                  value: '${service.totalCourses}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              _MetricCard(
                  label: '课时数',
                  value: '${service.totalLessons}',
                  trend: '本月+0'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricCard(
                  label: '进行中班级',
                  value: '${service.activeClasses}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              _MetricCard(
                  label: '学员数',
                  value: '${service.totalStudents}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              _MetricCard(
                  label: '待处理',
                  value: '3',
                  trend: '⚠'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _SectionPanel(
                    title: '专业列表',
                    items: programs.map((p) => _ListItem(
                      name: p.name,
                      subtitle: '${p.courses.length} 门课程 · ${p.status.label}',
                    )).toList(),
                    onViewAll: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ProgramScreen(),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SectionPanel(
                    title: '班级列表',
                    items: classes.map((c) => _ListItem(
                      name: c.name,
                      subtitle: '${c.refName} · ${c.status.label}',
                    )).toList(),
                    onViewAll: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ClassScreen(),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(trend,
                  style: TextStyle(
                      color: trend.startsWith('⚠')
                          ? Colors.orange
                          : Colors.green,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final List<_ListItem> items;
  final VoidCallback? onViewAll;

  const _SectionPanel({
    required this.title,
    required this.items,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('查看全部 →'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(items[i].name),
                  subtitle: Text(items[i].subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem {
  final String name;
  final String subtitle;

  const _ListItem({required this.name, required this.subtitle});
}
