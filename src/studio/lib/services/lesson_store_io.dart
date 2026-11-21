/// 桌面端实现：直接读写课时目录（仅在 `dart.library.io` 可用时被引入）。
library;

import 'dart:io';

import 'lesson_store.dart';

LessonStore createLessonStore(String path) => IoLessonStore(path);

class IoLessonStore extends LessonStore {
  @override
  final String path;

  IoLessonStore(this.path);

  Directory get _dir => Directory(path);

  void _checkName(String name) {
    if (name.isEmpty || name.contains('/') || name.contains('\\') || name.contains('..')) {
      throw ArgumentError('非法文件名：$name');
    }
  }

  @override
  List<String> listMarkdown() {
    if (!_dir.existsSync()) return const [];
    final files = _dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.md'))
        .toList()
      ..sort();
    return files;
  }

  File _file(String name) {
    _checkName(name);
    final file = File('$path${Platform.pathSeparator}$name');
    if (!file.existsSync()) {
      throw FileSystemException('文件不存在', file.path);
    }
    return file;
  }

  @override
  String read(String name) => _file(name).readAsStringSync();

  @override
  void write(String name, String content) {
    _checkName(name);
    if (!_dir.existsSync()) {
      _dir.createSync(recursive: true);
    }
    File('$path${Platform.pathSeparator}$name').writeAsStringSync(content);
  }
}
