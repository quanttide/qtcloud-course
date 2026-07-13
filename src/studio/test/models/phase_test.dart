import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/phase.dart';

void main() {
  final lessonJson = {
    'id': 'lesson-1',
    'title': '数据工程概述',
    'description': '数据工程的起源与发展',
    'duration': 45,
    'status': 'published',
    'sortOrder': 1,
  };

  final phaseJson = {
    'id': 'phase-1',
    'name': '基础阶段',
    'sortOrder': 1,
    'lessons': [lessonJson],
  };

  group('Phase', () {
    test('fromJson parses all fields', () {
      final phase = Phase.fromJson(phaseJson);
      expect(phase.id, 'phase-1');
      expect(phase.name, '基础阶段');
      expect(phase.sortOrder, 1);
      expect(phase.lessons.length, 1);
      expect(phase.lessons[0].title, '数据工程概述');
    });

    test('fromJson uses defaults for missing fields', () {
      final phase = Phase.fromJson({'id': 'p-1', 'name': 'test'});
      expect(phase.sortOrder, 0);
      expect(phase.lessons, isEmpty);
    });

    test('copyWith overrides specified fields', () {
      final phase = Phase.fromJson(phaseJson);
      final copy = phase.copyWith(name: '进阶阶段', sortOrder: 2);
      expect(copy.name, '进阶阶段');
      expect(copy.sortOrder, 2);
      expect(copy.id, phase.id);
      expect(copy.lessons, phase.lessons);
    });

    test('copyWith with no args returns equal object', () {
      final phase = Phase.fromJson(phaseJson);
      final copy = phase.copyWith();
      expect(copy.id, phase.id);
      expect(copy.name, phase.name);
      expect(copy.sortOrder, phase.sortOrder);
      expect(copy.lessons, phase.lessons);
    });
  });
}
