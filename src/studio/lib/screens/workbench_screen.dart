/// 课时工作台：单页两栏——左侧写课时 Markdown，右侧实时预览学员端形态。
///
/// 形态照 qtcloud-media 的 studio（左内容右预览）：
/// - 桌面端左栏直接打开 `data/profile/<course>/lessonN-*/` 正本目录，保存即写回正本；
///   浏览器端没有文件系统，打开本机 .md 装进内存，保存另存为下载文件
/// - 右栏按与 qtclass-lite 相同的块模型渲染，改一句当场看到学员看到的字
/// - 解析当场报错（缺标题、围栏未闭合、块悬空），不静默吞掉
library;

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/lesson.dart';
import '../services/lesson_md.dart';
import '../services/lesson_store.dart';
import '../services/lesson_store_web.dart';
import '../widgets/lesson_preview.dart';

/// 桌面端打开目录的入口，测试注入假实现即可（file_picker 是平台插件）
typedef PickDirectory = Future<String?> Function();

class WorkbenchScreen extends StatefulWidget {
  final PickDirectory? pickDirectory;
  final LessonStore? initialStore;

  const WorkbenchScreen({super.key, this.pickDirectory, this.initialStore});

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen> {
  LessonStore? _store;
  String? _sourceLabel;
  late TextEditingController _editor;
  PickDirectory get _pick =>
      widget.pickDirectory ?? () => FilePicker.platform.getDirectoryPath();

  List<String> _files = const [];
  String? _currentFile;
  String? _parseError;
  Lesson? _lesson;
  var _dirty = false;
  String? _savedMessage;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _editor = TextEditingController()..addListener(_onEdited);
    final store = widget.initialStore;
    if (store != null) {
      _store = store;
      _sourceLabel = store.path;
      _files = store.listMarkdown();
      if (_files.isNotEmpty) _openFile(_files.first);
    } else {
      _loadSample();
    }
  }

  /// 打开即放示例课时：页面没数据，看不出来这是干什么的
  Future<void> _loadSample() async {
    try {
      final md = await rootBundle.loadString('assets/sample-lesson.md');
      if (!mounted) return;
      final store = WebLessonStore()
        ..loadFiles({'hello-world.md': md});
      _adopt(store, '示例数据');
    } catch (_) {
      // 示例加载失败不影响使用：用户仍可自己打开目录 / 文件
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _editor.dispose();
    super.dispose();
  }

  void _onEdited() {
    if (!_dirty) setState(() => _dirty = true);
    _parse();
  }

  void _parse() {
    try {
      final lesson = parseLessonMd(
        _editor.text,
        name: _currentFile ?? '',
      );
      setState(() {
        _lesson = lesson;
        _parseError = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _lesson = null;
        _parseError = e.message;
      });
    }
  }

  void _openFile(String name) {
    setState(() {
      _currentFile = name;
      _editor.text = _store!.read(name);
      _dirty = false;
      _savedMessage = null;
    });
    _parse();
  }

  void _adopt(LessonStore store, String label) {
    setState(() {
      _store = store;
      _sourceLabel = label;
      _files = store.listMarkdown();
      _currentFile = null;
      _editor.clear();
      _lesson = null;
      _parseError = null;
      _dirty = false;
      _savedMessage = null;
    });
    if (_files.isNotEmpty) {
      _openFile(_files.first);
    } else {
      setState(() => _parseError = '这里没有 .md 文件');
    }
  }

  Future<void> _openSource() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );
      if (result == null) return;
      final files = <String, String>{};
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        files[file.name] = utf8.decode(bytes, allowMalformed: true);
      }
      if (files.isEmpty) return;
      final store = WebLessonStore()..loadFiles(files);
      _adopt(store, '浏览器内存');
      return;
    }

    final path = await _pick();
    if (path == null) return;
    _adopt(openLessonStore(path), path);
  }

  void _flash(String message) {
    setState(() {
      _dirty = false;
      _savedMessage = message;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _savedMessage = null);
    });
  }

  Future<void> _save() async {
    final store = _store;
    final name = _currentFile;
    if (store == null || name == null) return;
    store.write(name, _editor.text);

    if (store.isFileBacked) {
      _flash('已写回正本');
      return;
    }
    if (!kIsWeb) {
      // 示例或内存暂存：不假装写回正本
      _flash('已存到内存（不是正本）');
      return;
    }

    // 浏览器内存不是正本：另存一份给用户带走
    try {
      final saved = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: utf8.encode(_editor.text),
      );
      _flash(saved == null ? '已存到浏览器内存' : '已下载 $name');
    } catch (_) {
      _flash('已存到浏览器内存');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = _store;
    final saved = _savedMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('课时工作台'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _currentFile == null ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                saved ??
                    (_dirty ? '保存' : store == null ? '保存' : '已保存'),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左栏：来源 + 文件 + Markdown 编辑器
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sourceLabel ?? '未打开',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openSource,
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: Text(kIsWeb ? '打开 .md 文件' : '打开课时目录'),
                      ),
                    ],
                  ),
                ),
                if (_files.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _currentFile,
                      items: [
                        for (final f in _files)
                          DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => v == null ? null : _openFile(v),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _editor,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '# 课时标题\n\n## 步骤标题\n\n动作说明',
                      ),
                    ),
                  ),
                ),
                if (_parseError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: theme.colorScheme.errorContainer,
                    child: Text(
                      _parseError!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // 右栏：学员端形态预览
          Expanded(
            flex: 5,
            child: _lesson != null
                ? LessonPreview(lesson: _lesson!)
                : Center(
                    child: Text(
                      store == null
                          ? '先打开一个课时，这里就是学员看到的样子'
                          : _parseError == null
                              ? '左侧写课时，这里就是学员看到的样子'
                              : '解析失败，右侧不出预览——报错在左栏下方',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
