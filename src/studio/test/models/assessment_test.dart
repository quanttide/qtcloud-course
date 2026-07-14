import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/models/assessment.dart';

void main() {
  final fullJson = {
    'id': 'assess-1',
    'classId': 'class-1',
    'type': 'exam',
    'title': '期中考试',
    'fullScore': 100,
    'passScore': 60,
    'deadline': '2026-07-01',
  };

  final minimalJson = {
    'id': 'assess-2',
    'classId': 'class-1',
    'title': '课后作业一',
    'fullScore': 10,
    'passScore': 6,
    'deadline': '2026-06-15',
  };

  group('Assessment', () {
    test('fromJson parses all fields', () {
      final a = Assessment.fromJson(fullJson);
      expect(a.id, 'assess-1');
      expect(a.classId, 'class-1');
      expect(a.type, AssessmentType.exam);
      expect(a.title, '期中考试');
      expect(a.fullScore, 100);
      expect(a.passScore, 60);
      expect(a.deadline, '2026-07-01');
    });

    test('fromJson defaults type to homework', () {
      final a = Assessment.fromJson(minimalJson);
      expect(a.type, AssessmentType.homework);
      expect(a.title, '课后作业一');
      expect(a.fullScore, 10);
    });

    test('copyWith overrides specified fields', () {
      final a = Assessment.fromJson(fullJson);
      final copy = a.copyWith(title: '期末考', fullScore: 150);
      expect(copy.title, '期末考');
      expect(copy.fullScore, 150);
      expect(copy.id, a.id);
      expect(copy.classId, a.classId);
    });

    test('copyWith with no args returns equal object', () {
      final a = Assessment.fromJson(fullJson);
      final copy = a.copyWith();
      expect(copy.id, a.id);
      expect(copy.classId, a.classId);
      expect(copy.type, a.type);
      expect(copy.title, a.title);
      expect(copy.fullScore, a.fullScore);
      expect(copy.passScore, a.passScore);
      expect(copy.deadline, a.deadline);
    });

    test('toJson produces correct map', () {
      final a = Assessment.fromJson(fullJson);
      final json = a.toJson();
      expect(json['id'], 'assess-1');
      expect(json['classId'], 'class-1');
      expect(json['type'], 'exam');
      expect(json['title'], '期中考试');
      expect(json['fullScore'], 100);
      expect(json['passScore'], 60);
      expect(json['deadline'], '2026-07-01');
    });
  });
}
