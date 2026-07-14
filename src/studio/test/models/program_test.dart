import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/models/program.dart';

void main() {
  final lessonJson = {
    'id': 'lesson-1',
    'title': '数据工程概述',
    'description': '数据工程的起源与发展',
    'duration': 45,
    'status': 'published',
    'sortOrder': 1,
  };

  final lessonJsonMinimal = {
    'id': 'lesson-2',
    'title': 'Python基础',
  };

  final phaseJson = {
    'id': 'phase-1',
    'name': '基础阶段',
    'sortOrder': 1,
    'lessons': [lessonJson],
  };

  final courseJson = {
    'id': 'course-1',
    'name': '数据工程',
    'description': '核心技术',
    'status': 'published',
    'sortOrder': 1,
    'phases': [phaseJson],
  };

  final programJson = {
    'id': 'prog-1',
    'name': '大数据微专业',
    'description': '系统化课程体系',
    'status': 'published',
    'courses': [courseJson],
  };

  group('Lesson', () {
    test('fromJson parses all fields', () {
      final lesson = Lesson.fromJson(lessonJson);
      expect(lesson.id, 'lesson-1');
      expect(lesson.title, '数据工程概述');
      expect(lesson.description, '数据工程的起源与发展');
      expect(lesson.duration, 45);
      expect(lesson.status, ContentStatus.published);
      expect(lesson.sortOrder, 1);
      expect(lesson.scenes, isEmpty);
    });

    test('fromJson uses defaults for missing fields', () {
      final lesson = Lesson.fromJson(lessonJsonMinimal);
      expect(lesson.id, 'lesson-2');
      expect(lesson.title, 'Python基础');
      expect(lesson.description, '');
      expect(lesson.duration, 45);
      expect(lesson.status, ContentStatus.draft);
      expect(lesson.sortOrder, 0);
      expect(lesson.scenes, isEmpty);
    });

    test('copyWith overrides specified fields', () {
      final lesson = Lesson.fromJson(lessonJson);
      final copy = lesson.copyWith(title: '新标题', duration: 60, sortOrder: 2);
      expect(copy.title, '新标题');
      expect(copy.duration, 60);
      expect(copy.sortOrder, 2);
      expect(copy.id, lesson.id);
      expect(copy.description, lesson.description);
      expect(copy.status, lesson.status);
    });

    test('copyWith with no args returns equal object', () {
      final lesson = Lesson.fromJson(lessonJson);
      final copy = lesson.copyWith();
      expect(copy.id, lesson.id);
      expect(copy.title, lesson.title);
      expect(copy.description, lesson.description);
      expect(copy.duration, lesson.duration);
      expect(copy.status, lesson.status);
      expect(copy.sortOrder, lesson.sortOrder);
    });
  });

  group('Course', () {
    test('fromJson parses all fields with phases', () {
      final course = Course.fromJson(courseJson);
      expect(course.id, 'course-1');
      expect(course.name, '数据工程');
      expect(course.description, '核心技术');
      expect(course.status, ContentStatus.published);
      expect(course.phases.length, 1);
      expect(course.phases[0].name, '基础阶段');
      expect(course.phases[0].lessons[0].title, '数据工程概述');
      expect(course.sortOrder, 1);
    });

    test('fromJson defaults to empty phases and sortOrder 0', () {
      final course = Course.fromJson({'id': 'c-1', 'name': 'test'});
      expect(course.phases, isEmpty);
      expect(course.sortOrder, 0);
    });

    test('copyWith replaces phases and sortOrder', () {
      final course = Course.fromJson(courseJson);
      final copy = course.copyWith(phases: [], sortOrder: 3);
      expect(copy.phases, isEmpty);
      expect(copy.sortOrder, 3);
      expect(copy.id, course.id);
    });
  });

  group('Program', () {
    test('fromJson parses all fields with courses', () {
      final program = Program.fromJson(programJson);
      expect(program.id, 'prog-1');
      expect(program.name, '大数据微专业');
      expect(program.description, '系统化课程体系');
      expect(program.status, ContentStatus.published);
      expect(program.courses.length, 1);
      expect(program.courses[0].name, '数据工程');
    });

    test('fromJson defaults to empty courses list', () {
      final program = Program.fromJson({'id': 'p-1', 'name': 'test'});
      expect(program.courses, isEmpty);
    });

    test('fromJson handles empty courses array', () {
      final program = Program.fromJson({'id': 'p-1', 'name': 'test', 'courses': []});
      expect(program.courses, isEmpty);
    });

    test('copyWith overrides name and status', () {
      final program = Program.fromJson(programJson);
      final copy = program.copyWith(name: '新专业', status: ContentStatus.draft);
      expect(copy.name, '新专业');
      expect(copy.status, ContentStatus.draft);
      expect(copy.id, program.id);
    });

    test('toJson roundtrips through fromJson', () {
      final original = Program.fromJson(programJson);
      final json = original.toJson();
      final roundtrip = Program.fromJson(json);
      expect(roundtrip.id, original.id);
      expect(roundtrip.name, original.name);
      expect(roundtrip.description, original.description);
      expect(roundtrip.status, original.status);
      expect(roundtrip.courses.length, original.courses.length);
      expect(roundtrip.courses[0].name, original.courses[0].name);
    });
  });
}
