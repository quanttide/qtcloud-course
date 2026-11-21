import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/services/lesson_store.dart';

void main() {
  late Directory tempDir;
  late LessonStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lesson_store_test');
    store = openLessonStore(tempDir.path);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('列出目录里的 Markdown，按文件名排序', () {
    File('${tempDir.path}/02-b.md').writeAsStringSync('# b');
    File('${tempDir.path}/01-a.md').writeAsStringSync('# a');
    File('${tempDir.path}/index.json').writeAsStringSync('{}');

    expect(store.listMarkdown(), ['01-a.md', '02-b.md']);
  });

  test('读写往返', () {
    store.write('index.md', '# 课时\n');
    expect(store.read('index.md'), '# 课时\n');
  });

  test('不存在的目录列出空', () {
    final missing = openLessonStore('${tempDir.path}/nope');
    expect(missing.listMarkdown(), isEmpty);
  });

  test('拒绝跨目录文件名', () {
    expect(() => store.read('../escape.md'), throwsArgumentError);
    expect(() => store.write('a/b.md', 'x'), throwsArgumentError);
  });
}
