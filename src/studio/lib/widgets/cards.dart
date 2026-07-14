import 'package:flutter/material.dart';

/// 指标卡片，显示标签、大号数值和趋势文字。
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;

  const MetricCard({
    super.key,
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

/// 详情卡片，显示大号数值和下方标签。
class DetailCard extends StatelessWidget {
  final String label;
  final String value;

  const DetailCard({
    super.key,
    required this.label,
    required this.value,
  });

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

/// 信息行，左侧固定宽度标签，右侧值。
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

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
