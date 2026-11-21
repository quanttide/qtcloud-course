/// 浏览器端实现：没有文件系统，内容装在内存里（仅在非 `dart.library.io` 平台被引入）。
///
/// 打开 = 选中本机 .md 装进来；保存 = 写回内存，由工作台另存为下载文件。
library;

import 'lesson_store.dart';

LessonStore createLessonStore(String path) => WebLessonStore();

class WebLessonStore extends LessonStore {
  final _files = <String, String>{};

  @override
  String get path => '浏览器内存';

  @override
  List<String> listMarkdown() => (_files.keys.toList()..sort());

  @override
  String read(String name) {
    final content = _files[name];
    if (content == null) {
      throw StateError('文件不存在：$name');
    }
    return content;
  }

  @override
  void write(String name, String content) {
    if (name.isEmpty || name.contains('/') || name.contains('\\') || name.contains('..')) {
      throw ArgumentError('非法文件名：$name');
    }
    _files[name] = content;
  }

  @override
  void loadFiles(Map<String, String> files) {
    for (final entry in files.entries) {
      write(entry.key, entry.value);
    }
  }
}
