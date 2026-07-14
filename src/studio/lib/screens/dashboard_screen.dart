import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/cards.dart';
import 'program_screen.dart';
import 'class_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourseDataService>();
    final programs = service.programs;
    final classes = service.classes;

    return SingleChildScrollView(
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
              MetricCard(
                  label: '专业数',
                  value: '${service.totalPrograms}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              MetricCard(
                  label: '课程数',
                  value: '${service.totalCourses}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              MetricCard(
                  label: '课时数',
                  value: '${service.totalLessons}',
                  trend: '本月+0'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              MetricCard(
                  label: '进行中班级',
                  value: '${service.activeClasses}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              MetricCard(
                  label: '学员数',
                  value: '${service.totalStudents}',
                  trend: '本月+0'),
              const SizedBox(width: 16),
              MetricCard(
                  label: '待处理',
                  value: '3',
                  trend: '⚠'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 300,
                  child: _buildSectionPanel(context,
                    title: '专业列表',
                    items: programs.map((p) => _SimpleItem(
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 300,
                  child: _buildSectionPanel(context,
                    title: '班级列表',
                    items: classes.map((c) => _SimpleItem(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleItem {
  final String name;
  final String subtitle;

  const _SimpleItem({required this.name, required this.subtitle});
}

Widget _buildSectionPanel(BuildContext context, {
  required String title,
  required List<_SimpleItem> items,
  VoidCallback? onViewAll,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
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
