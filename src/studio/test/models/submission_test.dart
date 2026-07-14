import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/models/submission.dart';

void main() {
  final fullJson = {
    'id': 'sub-1',
    'assessmentId': 'assess-1',
    'studentId': 'student-1',
    'status': 'late',
    'score': 85.0,
    'comment': '做得不错',
    'submittedAt': '2026-06-20T10:00:00Z',
  };

  final minimalJson = {
    'id': 'sub-2',
    'assessmentId': 'assess-1',
    'studentId': 'student-2',
    'submittedAt': '2026-06-18T08:00:00Z',
  };

  group('Submission', () {
    test('fromJson parses all fields', () {
      final s = Submission.fromJson(fullJson);
      expect(s.id, 'sub-1');
      expect(s.assessmentId, 'assess-1');
      expect(s.studentId, 'student-1');
      expect(s.status, SubmissionStatus.late);
      expect(s.score, 85.0);
      expect(s.comment, '做得不错');
      expect(s.submittedAt, '2026-06-20T10:00:00Z');
    });

    test('fromJson defaults status and nullable fields', () {
      final s = Submission.fromJson(minimalJson);
      expect(s.id, 'sub-2');
      expect(s.status, SubmissionStatus.submitted);
      expect(s.score, isNull);
      expect(s.comment, isNull);
    });

    test('fromJson parses score from int', () {
      final json = Map<String, dynamic>.from(fullJson)..['score'] = 90;
      final s = Submission.fromJson(json);
      expect(s.score, 90.0);
    });

    test('copyWith overrides specified fields', () {
      final s = Submission.fromJson(fullJson);
      final copy = s.copyWith(score: 95.0, comment: '优秀');
      expect(copy.score, 95.0);
      expect(copy.comment, '优秀');
      expect(copy.id, s.id);
      expect(copy.status, s.status);
    });

    test('copyWith with no args returns equal object', () {
      final s = Submission.fromJson(fullJson);
      final copy = s.copyWith();
      expect(copy.id, s.id);
      expect(copy.assessmentId, s.assessmentId);
      expect(copy.studentId, s.studentId);
      expect(copy.status, s.status);
      expect(copy.score, s.score);
      expect(copy.comment, s.comment);
      expect(copy.submittedAt, s.submittedAt);
    });

    test('toJson omits null score and comment', () {
      final s = Submission.fromJson(minimalJson);
      final json = s.toJson();
      expect(json.containsKey('score'), false);
      expect(json.containsKey('comment'), false);
    });

    test('toJson includes all fields when non-null', () {
      final s = Submission.fromJson(fullJson);
      final json = s.toJson();
      expect(json['id'], 'sub-1');
      expect(json['assessmentId'], 'assess-1');
      expect(json['studentId'], 'student-1');
      expect(json['status'], 'late');
      expect(json['score'], 85.0);
      expect(json['comment'], '做得不错');
      expect(json['submittedAt'], '2026-06-20T10:00:00Z');
    });
  });
}
