import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/teacher.dart';

void main() {
  final fullJson = {
    'id': 'teacher-1',
    'name': '王教授',
    'email': 'wang@example.com',
    'title': '教授',
  };

  final minimalJson = {
    'id': 'teacher-2',
    'name': '李老师',
    'email': 'li@example.com',
  };

  group('Teacher', () {
    test('fromJson parses all fields', () {
      final t = Teacher.fromJson(fullJson);
      expect(t.id, 'teacher-1');
      expect(t.name, '王教授');
      expect(t.email, 'wang@example.com');
      expect(t.title, '教授');
    });

    test('fromJson handles missing title', () {
      final t = Teacher.fromJson(minimalJson);
      expect(t.id, 'teacher-2');
      expect(t.name, '李老师');
      expect(t.email, 'li@example.com');
      expect(t.title, isNull);
    });

    test('copyWith overrides specified fields', () {
      final t = Teacher.fromJson(fullJson);
      final copy = t.copyWith(name: '张教授', title: '副教授');
      expect(copy.name, '张教授');
      expect(copy.title, '副教授');
      expect(copy.id, t.id);
      expect(copy.email, t.email);
    });

    test('copyWith with no args returns equal object', () {
      final t = Teacher.fromJson(fullJson);
      final copy = t.copyWith();
      expect(copy.id, t.id);
      expect(copy.name, t.name);
      expect(copy.email, t.email);
      expect(copy.title, t.title);
    });

    test('toJson includes title when non-null', () {
      final t = Teacher.fromJson(fullJson);
      final json = t.toJson();
      expect(json['id'], 'teacher-1');
      expect(json['name'], '王教授');
      expect(json['email'], 'wang@example.com');
      expect(json['title'], '教授');
    });

    test('toJson omits title when null', () {
      final t = Teacher.fromJson(minimalJson);
      final json = t.toJson();
      expect(json.containsKey('title'), false);
    });
  });
}
