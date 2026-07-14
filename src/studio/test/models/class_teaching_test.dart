import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/models/class_teaching.dart';

void main() {
  final fullJson = {
    'id': 'class-1',
    'name': '浙理班级',
    'refName': '大数据微专业',
    'refType': 'program',
    'refId': 'prog-1',
    'status': 'active',
    'startDate': '2026-03-01',
    'endDate': '2026-07-15',
    'studentCount': 45,
    'progress': 0.6,
    'teacherIds': ['teacher-1'],
    'studentIds': ['student-1', 'student-2'],
  };

  final minimalJson = {
    'id': 'class-2',
    'name': '杭电班级',
    'refName': 'Python基础',
    'refId': 'course-2',
    'startDate': '2026-05-10',
    'endDate': '2026-08-20',
  };

  group('ClassTeaching', () {
    test('fromJson parses all fields', () {
      final c = ClassTeaching.fromJson(fullJson);
      expect(c.id, 'class-1');
      expect(c.name, '浙理班级');
      expect(c.refName, '大数据微专业');
      expect(c.refType, 'program');
      expect(c.refId, 'prog-1');
      expect(c.status, ClassStatus.active);
      expect(c.startDate, '2026-03-01');
      expect(c.endDate, '2026-07-15');
      expect(c.studentCount, 45);
      expect(c.progress, 0.6);
      expect(c.teacherIds, ['teacher-1']);
      expect(c.studentIds, ['student-1', 'student-2']);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final c = ClassTeaching.fromJson(minimalJson);
      expect(c.id, 'class-2');
      expect(c.name, '杭电班级');
      expect(c.refType, 'program');
      expect(c.status, ClassStatus.preparing);
      expect(c.studentCount, 0);
      expect(c.progress, 0.0);
      expect(c.teacherIds, []);
      expect(c.studentIds, []);
    });

    test('fromJson parses progress from int', () {
      final json = Map<String, dynamic>.from(fullJson)..['progress'] = 1;
      final c = ClassTeaching.fromJson(json);
      expect(c.progress, 1.0);
    });

    test('copyWith overrides specified fields', () {
      final c = ClassTeaching.fromJson(fullJson);
      final copy = c.copyWith(name: '新班级', status: ClassStatus.ended);
      expect(copy.name, '新班级');
      expect(copy.status, ClassStatus.ended);
      expect(copy.id, c.id);
      expect(copy.studentCount, c.studentCount);
    });

    test('copyWith with no args returns equal object', () {
      final c = ClassTeaching.fromJson(fullJson);
      final copy = c.copyWith();
      expect(copy.id, c.id);
      expect(copy.name, c.name);
      expect(copy.refName, c.refName);
      expect(copy.refType, c.refType);
      expect(copy.refId, c.refId);
      expect(copy.status, c.status);
      expect(copy.startDate, c.startDate);
      expect(copy.endDate, c.endDate);
      expect(copy.studentCount, c.studentCount);
      expect(copy.progress, c.progress);
      expect(copy.teacherIds, c.teacherIds);
      expect(copy.studentIds, c.studentIds);
    });
  });
}
