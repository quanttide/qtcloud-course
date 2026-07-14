import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/student.dart';

void main() {
  final fullJson = {
    'id': 'student-1',
    'name': '张三',
    'email': 'zhangsan@example.com',
    'avatar': 'https://example.com/avatar.png',
  };

  final minimalJson = {
    'id': 'student-2',
    'name': '李四',
    'email': 'lisi@example.com',
  };

  group('Student', () {
    test('fromJson parses all fields', () {
      final s = Student.fromJson(fullJson);
      expect(s.id, 'student-1');
      expect(s.name, '张三');
      expect(s.email, 'zhangsan@example.com');
      expect(s.avatar, 'https://example.com/avatar.png');
    });

    test('fromJson handles missing avatar', () {
      final s = Student.fromJson(minimalJson);
      expect(s.id, 'student-2');
      expect(s.name, '李四');
      expect(s.email, 'lisi@example.com');
      expect(s.avatar, isNull);
    });

    test('copyWith overrides specified fields', () {
      final s = Student.fromJson(fullJson);
      final copy = s.copyWith(name: '王五', email: 'wangwu@example.com');
      expect(copy.name, '王五');
      expect(copy.email, 'wangwu@example.com');
      expect(copy.id, s.id);
      expect(copy.avatar, s.avatar);
    });

    test('copyWith with no args returns equal object', () {
      final s = Student.fromJson(fullJson);
      final copy = s.copyWith();
      expect(copy.id, s.id);
      expect(copy.name, s.name);
      expect(copy.email, s.email);
      expect(copy.avatar, s.avatar);
    });

    test('toJson includes avatar when non-null', () {
      final s = Student.fromJson(fullJson);
      final json = s.toJson();
      expect(json['id'], 'student-1');
      expect(json['name'], '张三');
      expect(json['email'], 'zhangsan@example.com');
      expect(json['avatar'], 'https://example.com/avatar.png');
    });

    test('toJson omits avatar when null', () {
      final s = Student.fromJson(minimalJson);
      final json = s.toJson();
      expect(json.containsKey('avatar'), false);
    });
  });
}
