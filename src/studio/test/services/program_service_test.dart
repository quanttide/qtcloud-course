import 'package:flutter_test/flutter_test.dart';
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
}
