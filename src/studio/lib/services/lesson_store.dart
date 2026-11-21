/// 课时内容读写：Studio 直接打开 `data/profile/<course>/lessonN-*/` 正本，
/// 读写其中的 Markdown。没有私有副本——Studio 存的就是正本，保存即落盘。
///
/// 桌面端走文件系统（`lesson_store_io.dart`），浏览器端没有文件系统，
/// 走内存（`lesson_store_web.dart`）：打开 .md 装进来、保存回内存并可下载。
/// 平台分叉只在这一层，编辑器与预览两边共用。
library;

import 'lesson_store_web.dart'
    if (dart.library.io) 'lesson_store_io.dart' as impl;

abstract class LessonStore {
  /// 展示用的来源路径：桌面端是目录，浏览器端是「浏览器内存」
  String get path;

  /// 目录里的 Markdown 文件，按文件名排序
  List<String> listMarkdown();

  String read(String name);

  void write(String name, String content);

  /// 浏览器端装入选中的 .md；桌面端是空操作
  void loadFiles(Map<String, String> files) {}
}

/// 按平台打开一个存储：桌面端给目录路径，浏览器端参数只作占位
LessonStore openLessonStore(String path) => impl.createLessonStore(path);
