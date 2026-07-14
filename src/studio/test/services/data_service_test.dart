import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qtcloud_course_studio/models/enums.dart';
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

    test('baseUrl null uses assets mode', () {
      final service = CourseDataService();
      expect(service.baseUrl, isNull);
    });

    test('baseUrl non-null sets API mode', () {
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      expect(service.baseUrl, 'http://localhost:8080');
    });

    test('initial state is not loaded, no error, not loading', () {
      final service = CourseDataService();
      expect(service.loaded, false);
      expect(service.error, isNull);
      expect(service.loading, false);
    });
  });

  group('CourseDataService CRUD', () {
    test('createProgram adds to list', () {
      final service = CourseDataService();
      final p = service.createProgram('Test', 'Desc');
      expect(service.totalPrograms, 1);
      expect(p.name, 'Test');
      expect(p.description, 'Desc');
      expect(p.status, ContentStatus.draft);
    });

    test('updateProgram modifies existing', () {
      final service = CourseDataService();
      final p = service.createProgram('Old', '');
      service.updateProgram(p.id, name: 'New', description: 'Updated');
      expect(service.programs[0].name, 'New');
      expect(service.programs[0].description, 'Updated');
    });

    test('deleteProgram removes from list', () {
      final service = CourseDataService();
      service.createProgram('P1', '');
      service.createProgram('P2', '');
      service.deleteProgram(service.programs[0].id);
      expect(service.totalPrograms, 1);
      expect(service.programs[0].name, 'P2');
    });

    test('createCourse adds to program', () {
      final service = CourseDataService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C1', 'Desc');
      expect(service.totalCourses, 1);
      expect(service.programs[0].courses[0].name, 'C1');
    });

    test('deleteCourse removes from program', () {
      final service = CourseDataService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C1', '');
      service.createCourse(p.id, 'C2', '');
      service.deleteCourse(p.id, service.programs[0].courses[0].id);
      expect(service.totalCourses, 1);
      expect(service.programs[0].courses[0].name, 'C2');
    });

    test('createPhase adds to course', () {
      final service = CourseDataService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph1');
      expect(service.programs[0].courses[0].phases.length, 1);
      expect(service.programs[0].courses[0].phases[0].name, 'Ph1');
    });

    test('createLesson adds to phase', () {
      final service = CourseDataService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph');
      final ph = service.programs[0].courses[0].phases[0];
      service.createLesson(p.id, c.id, ph.id, 'L1');
      expect(
        service.programs[0].courses[0].phases[0].lessons.length, 1,
      );
      expect(
        service.programs[0].courses[0].phases[0].lessons[0].title, 'L1',
      );
    });

    test('delete cascade removes nested correctly', () {
      final service = CourseDataService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph');
      final ph = service.programs[0].courses[0].phases[0];
      service.createLesson(p.id, c.id, ph.id, 'L');

      service.deleteProgram(p.id);
      expect(service.totalPrograms, 0);
    });
  });

  group('CourseDataService API mode', () {
    test('load sets error on HTTP failure', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));

      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();

      expect(service.loaded, false);
      expect(service.error, contains('404'));
      expect(service.loading, false);
    });

    test('load parses programs and classes on success', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/programs') {
          return http.Response('[{"id":"p1","name":"P1"}]', 200);
        }
        if (request.url.path == '/classes') {
          return http.Response('[{"id":"c1","name":"C1","refName":"Test Class","refId":"p1","status":"active","startDate":"2026-07-01","endDate":"2026-08-01","studentCount":20}]', 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();

      expect(service.error, isNull);
      expect(service.loaded, true);
      expect(service.totalPrograms, 1);
    });
  });
}
