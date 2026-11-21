import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/services/lesson_store_web.dart';

/// 浏览器端没有文件系统：内容装内存，打开 = 装入选中的 .md
void main() {
  test('装入、读写与列表', () {
    final store = createLessonStore('');
    store.loadFiles({'02-b.md': '# b', '01-a.md': '# a'});

    expect(store.path, '浏览器内存');
    expect(store.listMarkdown(), ['01-a.md', '02-b.md']);
    expect(store.read('01-a.md'), '# a');

    store.write('01-a.md', '# a 改过');
    expect(store.read('01-a.md'), '# a 改过');
  });

  test('缺文件与非法文件名都报错', () {
    final store = createLessonStore('');
    expect(() => store.read('nope.md'), throwsStateError);
    expect(() => store.write('../escape.md', 'x'), throwsArgumentError);
    expect(() => store.write('sub/a.md', 'x'), throwsArgumentError);
  });
}
