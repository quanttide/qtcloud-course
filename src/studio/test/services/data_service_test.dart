import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/program.dart';
import 'package:qtcloud_course_studio/models/phase.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';

void main() {
  group('CourseDataService', () {
    test('totalPrograms counts programs', () {
      final service = CourseDataService();
      service.programs.addAll([
        Program(id: 'p1', name: 'P1'),
      ]);
      expect(service.totalPrograms, 1);
    });

    test('totalCourses counts courses across programs', () {
      final service = CourseDataService();
      service.programs.addAll([
        Program(id: 'p1', name: 'P1', courses: [
          Course(id: 'c1', name: 'C1'),
          Course(id: 'c2', name: 'C2'),
        ]),
      ]);
      expect(service.totalCourses, 2);
    });

    test('totalLessons counts lessons across phases', () {
      final service = CourseDataService();
      service.programs.addAll([
        Program(id: 'p1', name: 'P1', courses: [
          Course(id: 'c1', name: 'C1', phases: [
            Phase(id: 'ph1', name: '基础', lessons: [
              Lesson(id: 'l1', title: '概述'),
              Lesson(id: 'l2', title: '进阶'),
            ]),
          ]),
        ]),
      ]);
      expect(service.totalLessons, 2);
    });

    test('totalLessons returns 0 when no lessons', () {
      final service = CourseDataService();
      service.programs.addAll([
        Program(id: 'p1', name: 'P1', courses: [
          Course(id: 'c1', name: 'C1'),
        ]),
      ]);
      expect(service.totalLessons, 0);
    });
  });
}
