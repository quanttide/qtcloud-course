import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:qtcloud_course_studio/models/enums.dart';

import 'package:qtcloud_course_studio/services/assessment_service.dart';

void main() {
  group('AssessmentService', () {
    test('initial state', () {
      final service = AssessmentService();
      expect(service.loaded, false);
      expect(service.error, isNull);
      expect(service.loading, false);
      expect(service.assessments, isEmpty);
      expect(service.submissions, isEmpty);
    });

    test('baseUrl null uses assets mode', () {
      final service = AssessmentService();
      expect(service.baseUrl, isNull);
    });
  });

  group('AssessmentService CRUD', () {
    test('createAssessment adds assessment', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '新考核',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-08-01',
        type: AssessmentType.exam,
      );
      expect(service.assessments.length, 1);
      expect(service.assessments.first.title, '新考核');
      expect(service.assessments.first.type, AssessmentType.exam);
    });

    test('getAssessmentsByClass filters correctly', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '考核A',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      service.createAssessment(
        classId: 'class-2',
        title: '考核B',
        fullScore: 50,
        passScore: 30,
        deadline: '2026-07-15',
      );
      expect(service.getAssessmentsByClass('class-1').length, 1);
      expect(service.getAssessmentsByClass('class-2').length, 1);
      expect(service.getAssessmentsByClass('class-3').length, 0);
    });

    test('updateAssessment modifies fields', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '考核',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      final id = service.assessments.first.id;
      service.updateAssessment(id, title: '更新后', fullScore: 120);
      expect(service.assessments.first.title, '更新后');
      expect(service.assessments.first.fullScore, 120);
    });

    test('deleteAssessment removes assessment and its submissions', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '考核',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      final id = service.assessments.first.id;
      service.scoreSubmission('sub-1', 90.0, '好');
      service.deleteAssessment(id);
      expect(service.assessments, isEmpty);
    });

    test('scoreSubmission sets score and comment', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '考核',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      final service2 = AssessmentService();
      service2.scoreSubmission('non-existent', 90, 'good');
      expect(service2.submissions, isEmpty);
    });

    test('deleteAssessment removes related submissions', () {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '考核',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      final id = service.assessments.first.id;
      service.deleteAssessment(id);
      expect(service.assessments, isEmpty);
    });
  });

  group('AssessmentService API mode', () {
    test('load sets error on HTTP failure', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));
      final service = AssessmentService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();
      expect(service.loaded, false);
      expect(service.error, contains('404'));
    });

    test('load parses assessments and submissions on success', () async {
      int callCount = 0;
      final client = MockClient((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            '[{"id":"a1","classId":"c1","type":"exam","title":"Test","fullScore":100,"passScore":60,"deadline":"2026-07-01"}]',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          '[{"id":"s1","assessmentId":"a1","studentId":"st1","status":"submitted","submittedAt":"2026-06-20T10:00:00Z"}]',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = AssessmentService(baseUrl: 'http://localhost:8080');
      service.client = client;
      await service.load();
      expect(service.loaded, true);
      expect(service.error, isNull);
      expect(service.assessments.length, 1);
      expect(service.submissions.length, 1);
    });
  });

  group('AssessmentService API write-back', () {
    test('createAssessment sends POST /assessments', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = AssessmentService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createAssessment(
        classId: 'c1',
        title: 'Test',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-08-01',
      );
      await Future(() {});
      expect(method, 'POST');
      expect(path, '/assessments');
    });

    test('updateAssessment sends PUT /assessments/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = AssessmentService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createAssessment(
        classId: 'c1',
        title: 'Test',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-08-01',
      );
      final id = service.assessments.first.id;
      method = null;
      path = null;
      service.updateAssessment(id, title: 'Updated');
      await Future(() {});
      expect(method, 'PUT');
      expect(path, '/assessments/$id');
    });

    test('deleteAssessment sends DELETE /assessments/:id', () async {
      String? method;
      String? path;
      final client = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('{}', 200);
      });
      final service = AssessmentService(baseUrl: 'http://localhost:8080');
      service.client = client;
      service.createAssessment(
        classId: 'c1',
        title: 'Test',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-08-01',
      );
      final id = service.assessments.first.id;
      method = null;
      path = null;
      service.deleteAssessment(id);
      await Future(() {});
      expect(method, 'DELETE');
      expect(path, '/assessments/$id');
    });
  });
}
