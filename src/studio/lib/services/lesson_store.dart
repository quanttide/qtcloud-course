/// 课时目录读写：Studio 直接打开 `data/profile/<course>/lessonN-*/` 这样的正本目录，
/// 读写其中的 Markdown。没有私有副本——Studio 存的就是正本，保存即落盘。
library;

import 'dart:io';

class LessonStore {
  /// 课时目录，如 `data/profile/vibe-creating/lesson1-hello-world`
  final Directory dir;

  const LessonStore(this.dir);

  /// 目录里的 Markdown 文件，按文件名排序
  List<String> listMarkdown() {
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.md'))
        .toList()
      ..sort();
    return files;
  }

  File _file(String name) {
    if (name.isEmpty || name.contains('/') || name.contains('\\') || name.contains('..')) {
      throw ArgumentError('非法文件名：$name');
    }
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    if (!file.existsSync()) {
      throw FileSystemException('文件不存在', file.path);
    }
    return file;
  }

  String read(String name) => _file(name).readAsStringSync();

  void write(String name, String content) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    // 文件名只允许是目录内的 basename，先校验再落盘
    if (name.isEmpty || name.contains('/') || name.contains('\\') || name.contains('..')) {
      throw ArgumentError('非法文件名：$name');
    }
    File('${dir.path}${Platform.pathSeparator}$name').writeAsStringSync(content);
  }
}
