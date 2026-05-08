import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/enums.dart';

void main() {
  group('ContentStatus', () {
    test('fromString returns published for "published"', () {
      expect(ContentStatus.fromString('published'), ContentStatus.published);
    });

    test('fromString returns draft for unknown value', () {
      expect(ContentStatus.fromString('unknown'), ContentStatus.draft);
    });

    test('fromString returns draft for empty value', () {
      expect(ContentStatus.fromString(''), ContentStatus.draft);
    });

    test('label returns Chinese for draft', () {
      expect(ContentStatus.draft.label, '草稿');
    });

    test('label returns Chinese for published', () {
      expect(ContentStatus.published.label, '已发布');
    });
  });

  group('ClassStatus', () {
    test('fromString returns active for "active"', () {
      expect(ClassStatus.fromString('active'), ClassStatus.active);
    });

    test('fromString returns ended for "ended"', () {
      expect(ClassStatus.fromString('ended'), ClassStatus.ended);
    });

    test('fromString returns preparing for unknown value', () {
      expect(ClassStatus.fromString('unknown'), ClassStatus.preparing);
    });

    test('fromString returns preparing for empty value', () {
      expect(ClassStatus.fromString(''), ClassStatus.preparing);
    });

    test('label returns Chinese for preparing', () {
      expect(ClassStatus.preparing.label, '筹备中');
    });

    test('label returns Chinese for active', () {
      expect(ClassStatus.active.label, '进行中');
    });

    test('label returns Chinese for ended', () {
      expect(ClassStatus.ended.label, '已结束');
    });
  });
}
