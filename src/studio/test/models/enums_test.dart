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
}
