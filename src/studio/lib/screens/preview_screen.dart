import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  final String lessonId;

  const PreviewScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('试听')),
      body: Center(
        child: Text('Preview: $lessonId',
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
