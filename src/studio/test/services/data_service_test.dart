import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qtcloud_course_studio/models/class_teaching.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';

void main() {
  group('CourseDataService', () {
    test('initial state', () {
      final service = CourseDataService();
      expect(service.loaded, false);
      expect(service.error, isNull);
      expect(service.loading, false);
      expect(service.classes, isEmpty);
    });

    test('baseUrl null uses assets mode', () {
      final service = CourseDataService();
      expect(service.baseUrl, isNull);
    });

    test('baseUrl non-null sets API mode', () {
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      expect(service.baseUrl, 'http://localhost:8080');
    });

    test('activeClasses counts correctly', () {
      final service = CourseDataService();
      service.classes.addAll([
        ClassTeaching(id: '1', name: 'A', refName: 'R', refId: 'P1', status: ClassStatus.active, startDate: '', endDate: ''),
        ClassTeaching(id: '2', name: 'B', refName: 'R', refId: 'P1', status: ClassStatus.preparing, startDate: '', endDate: ''),
      ]);
      expect(service.activeClasses, 1);
    });

    test('totalStudents sums correctly', () {
      final service = CourseDataService();
      service.classes.addAll([
        ClassTeaching(id: '1', name: 'A', refName: 'R', refId: 'P1', status: ClassStatus.active, startDate: '', endDate: '', studentCount: 30),
        ClassTeaching(id: '2', name: 'B', refName: 'R', refId: 'P1', status: ClassStatus.active, startDate: '', endDate: '', studentCount: 20),
      ]);
      expect(service.totalStudents, 50);
    });
  });

  group('CourseDataService API mode', () {
    test('load falls back to local JSON on HTTP failure', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();
      expect(service.loaded, true);
      expect(service.offlineFallback, true);
    });

    test('load parses classes on success', () async {
      final client = MockClient((_) async =>
        http.Response('[{"id":"c1","name":"C1","refName":"Test","refId":"p1","status":"active","startDate":"2026-07-01","endDate":"2026-08-01","studentCount":20}]', 200, headers: {'content-type': 'application/json; charset=utf-8'}),
      );
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();
      expect(service.loaded, true);
      expect(service.error, isNull);
      expect(service.classes.length, 1);
    });
  });

  group('CourseDataService API write-back', () {
    test('createClass sends POST /classes', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createClass(
        name: 'Test',
        refName: 'P1',
        refId: 'p1',
        startDate: '2026-07-01',
        endDate: '2026-08-01',
      );
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/classes');
    });

    test('updateClass sends PUT /classes/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createClass(
        name: 'Test',
        refName: 'P1',
        refId: 'p1',
        startDate: '2026-07-01',
        endDate: '2026-08-01',
      );
      final id = service.classes.first.id;
      method = null;
      path = null;
      service.updateClass(id, name: 'Updated');
      await Future(() {});
      expect(method, 'PUT');
      expect(path, '/classes/$id');
    });

    test('deleteClass sends DELETE /classes/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = CourseDataService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createClass(
        name: 'Test',
        refName: 'P1',
        refId: 'p1',
        startDate: '2026-07-01',
        endDate: '2026-08-01',
      );
      final id = service.classes.first.id;
      method = null;
      path = null;
      service.deleteClass(id);
      await Future(() {});
      expect(method, 'DELETE');
      expect(path, '/classes/$id');
    });
  });
}
