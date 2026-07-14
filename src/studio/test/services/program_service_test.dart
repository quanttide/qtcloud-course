import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/program_service.dart';

void main() {
  group('ProgramService', () {
    test('initial state', () {
      final service = ProgramService();
      expect(service.loaded, false);
      expect(service.error, isNull);
      expect(service.loading, false);
      expect(service.programs, isEmpty);
    });

    test('totalPrograms counts programs', () {
      final service = ProgramService();
      service.createProgram('P1', '');
      service.createProgram('P2', '');
      expect(service.totalPrograms, 2);
    });

    test('totalCourses counts courses across programs', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C1', '');
      service.createCourse(p.id, 'C2', '');
      expect(service.totalCourses, 2);
    });

    test('totalLessons counts lessons across phases', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph');
      final ph = service.programs[0].courses[0].phases[0];
      service.createLesson(p.id, c.id, ph.id, 'L1');
      service.createLesson(p.id, c.id, ph.id, 'L2');
      expect(service.totalLessons, 2);
    });
  });

  group('ProgramService CRUD', () {
    test('createProgram adds to list', () {
      final service = ProgramService();
      final p = service.createProgram('Test', 'Desc');
      expect(service.totalPrograms, 1);
      expect(p.name, 'Test');
      expect(p.status, ContentStatus.draft);
    });

    test('updateProgram modifies existing', () {
      final service = ProgramService();
      final p = service.createProgram('Old', '');
      service.updateProgram(p.id, name: 'New');
      expect(service.programs[0].name, 'New');
    });

    test('deleteProgram removes from list', () {
      final service = ProgramService();
      service.createProgram('P1', '');
      service.createProgram('P2', '');
      service.deleteProgram(service.programs[0].id);
      expect(service.totalPrograms, 1);
      expect(service.programs[0].name, 'P2');
    });

    test('createCourse adds to program', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C1', 'Desc');
      expect(service.totalCourses, 1);
      expect(service.programs[0].courses[0].name, 'C1');
    });

    test('deleteCourse removes from program', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C1', '');
      service.createCourse(p.id, 'C2', '');
      service.deleteCourse(p.id, service.programs[0].courses[0].id);
      expect(service.totalCourses, 1);
      expect(service.programs[0].courses[0].name, 'C2');
    });

    test('createPhase adds to course', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph1');
      expect(service.programs[0].courses[0].phases.length, 1);
    });

    test('createLesson adds to phase', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.createCourse(p.id, 'C', '');
      final c = service.programs[0].courses[0];
      service.createPhase(p.id, c.id, 'Ph');
      final ph = service.programs[0].courses[0].phases[0];
      service.createLesson(p.id, c.id, ph.id, 'L1');
      expect(service.programs[0].courses[0].phases[0].lessons.length, 1);
    });

    test('delete cascade removes nested correctly', () {
      final service = ProgramService();
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

  group('ProgramService Publish', () {
    test('publishProgram changes status to published', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      expect(p.status, ContentStatus.draft);
      service.publishProgram(p.id);
      expect(service.programs[0].status, ContentStatus.published);
    });

    test('unpublishProgram changes status back to draft', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      service.publishProgram(p.id);
      service.unpublishProgram(p.id);
      expect(service.programs[0].status, ContentStatus.draft);
    });

    test('publishCourse changes course status', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      expect(c!.status, ContentStatus.draft);
      service.publishCourse(p.id, c.id);
      expect(service.programs[0].courses[0].status, ContentStatus.published);
    });

    test('publishLesson changes lesson status', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      final ph = service.createPhase(p.id, c!.id, 'Ph');
      final l = service.createLesson(p.id, c.id, ph!.id, 'L');
      expect(l!.status, ContentStatus.draft);
      service.publishLesson(p.id, c.id, ph.id, l.id);
      expect(
        service.programs[0].courses[0].phases[0].lessons[0].status,
        ContentStatus.published,
      );
    });

    test('draftLessonCountInCourse counts correctly', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      final ph = service.createPhase(p.id, c!.id, 'Ph');
      service.createLesson(p.id, c.id, ph!.id, 'Draft1');
      final l2 = service.createLesson(p.id, c.id, ph.id, 'Published');
      service.publishLesson(p.id, c.id, ph.id, l2!.id);
      expect(service.draftLessonCountInCourse(p.id, c.id), 1);
    });
  });

  group('ProgramService Import/Export', () {
    test('exportProgramsJson returns valid JSON', () {
      final service = ProgramService();
      service.createProgram('P1', '');
      final json = service.exportProgramsJson();
      expect(json, contains('P1'));
      expect(json, contains('"programs"'));
    });

    test('mergeProgramsFromJson merges new programs', () {
      final service = ProgramService();
      service.createProgram('Existing', '');
      const json = '{"programs":[{"id":"new1","name":"Imported","description":"","status":"draft","courses":[]}]}';
      final ok = service.mergeProgramsFromJson(json);
      expect(ok, true);
      expect(service.totalPrograms, 2);
    });

    test('mergeProgramsFromJson returns false on invalid JSON', () {
      final service = ProgramService();
      final ok = service.mergeProgramsFromJson('not json');
      expect(ok, false);
    });
  });

  group('ProgramService API write-back', () {
    test('createProgram sends POST /programs', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createProgram('P1', 'Desc');
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/programs');
    });

    test('updateProgram sends PUT /programs/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P1', '');
      method = null;
      path = null;
      service.updateProgram(p.id, name: 'P2');
      await Future(() {});
      expect(method, 'PUT');
      expect(path, '/programs/${p.id}');
    });

    test('deleteProgram sends DELETE /programs/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P1', '');
      method = null;
      path = null;
      service.deleteProgram(p.id);
      await Future(() {});
      expect(method, 'DELETE');
      expect(path, '/programs/${p.id}');
    });

    test('createCourse sends POST /courses', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      method = null;
      path = null;
      service.createCourse(p.id, 'C', '');
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/courses');
    });

    test('updateCourse sends PUT /courses/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      method = null;
      path = null;
      service.updateCourse(p.id, c!.id, name: 'C2');
      await Future(() {});
      expect(method, 'PUT');
      expect(path, '/courses/${c.id}');
    });

    test('deleteCourse sends DELETE /courses/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      method = null;
      path = null;
      service.deleteCourse(p.id, c!.id);
      await Future(() {});
      expect(method, 'DELETE');
      expect(path, '/courses/${c.id}');
    });

    test('createPhase sends POST /phases', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      method = null;
      path = null;
      service.createPhase(p.id, c!.id, 'Ph');
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/phases');
    });

    test('createLesson sends POST /lessons', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      final ph = service.createPhase(p.id, c!.id, 'Ph');
      method = null;
      path = null;
      service.createLesson(p.id, c.id, ph!.id, 'L');
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/lessons');
    });

    test('deleteLesson sends DELETE /lessons/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = ProgramService(baseUrl: 'http://localhost:8080');
      service.client = client;
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      final ph = service.createPhase(p.id, c!.id, 'Ph');
      final l = service.createLesson(p.id, c.id, ph!.id, 'L');
      method = null;
      path = null;
      service.deleteLesson(p.id, c.id, ph.id, l!.id);
      await Future(() {});
      expect(method, 'DELETE');
      expect(path, '/lessons/${l.id}');
    });
  });

  group('ProgramService Reorder', () {
    test('reorderProgram swaps list order', () {
      final service = ProgramService();
      final p1 = service.createProgram('A', '');
      final p2 = service.createProgram('B', '');
      service.reorderProgram(1, 0);
      expect(service.programs[0].id, p2.id);
      expect(service.programs[1].id, p1.id);
    });

    test('reorderCourses reorders within program', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c1 = service.createCourse(p.id, 'C1', '')!;
      final c2 = service.createCourse(p.id, 'C2', '')!;
      service.reorderCourses(p.id, 1, 0);
      expect(service.programs[0].courses[0].id, c2.id);
      expect(service.programs[0].courses[1].id, c1.id);
    });

    test('reorderPhases reorders within course', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '')!;
      final ph1 = service.createPhase(p.id, c.id, 'Ph1')!;
      final ph2 = service.createPhase(p.id, c.id, 'Ph2')!;
      service.reorderPhases(p.id, c.id, 1, 0);
      expect(service.programs[0].courses[0].phases[0].id, ph2.id);
      expect(service.programs[0].courses[0].phases[1].id, ph1.id);
    });

    test('reorderLessons reorders within phase', () {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '')!;
      final ph = service.createPhase(p.id, c.id, 'Ph')!;
      final l1 = service.createLesson(p.id, c.id, ph.id, 'L1')!;
      final l2 = service.createLesson(p.id, c.id, ph.id, 'L2')!;
      service.reorderLessons(p.id, c.id, ph.id, 1, 0);
      expect(service.programs[0].courses[0].phases[0].lessons[0].id, l2.id);
      expect(service.programs[0].courses[0].phases[0].lessons[1].id, l1.id);
    });
  });
}
