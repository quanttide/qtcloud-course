/// 课时工作台：单页两栏——左侧写课时 Markdown，右侧实时预览学员端形态。
///
/// 形态照 qtcloud-media 的 studio（左内容右预览）：
/// - 左栏直接打开 `data/profile/<course>/lessonN-*/` 正本目录，保存即写回正本
/// - 右栏按与 qtclass-lite 相同的块模型渲染，改一句当场看到学员看到的字
/// - 解析当场报错（缺标题、围栏未闭合、块悬空），不静默吞掉
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/lesson_md.dart';
import '../services/lesson_store.dart';
import '../widgets/lesson_preview.dart';

/// 打开目录的入口，测试注入假实现即可（file_picker 是平台插件）
typedef PickDirectory = Future<String?> Function();

class WorkbenchScreen extends StatefulWidget {
  final PickDirectory? pickDirectory;
  final LessonStore? initialStore;

  const WorkbenchScreen({super.key, this.pickDirectory, this.initialStore});

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends State<WorkbenchScreen> {
  late LessonStore _store;
  late TextEditingController _editor;
  PickDirectory get _pick =>
      widget.pickDirectory ?? () => FilePicker.platform.getDirectoryPath();

  List<String> _files = const [];
  String? _currentFile;
  String? _parseError;
  Lesson? _lesson;
  var _dirty = false;
  var _savedFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _store = widget.initialStore ??
        LessonStore(Directory('${Directory.systemTemp.path}/qtcloud-course-studio'));
    _editor = TextEditingController()..addListener(_onEdited);
    _files = _store.listMarkdown();
    if (_files.isNotEmpty) _openFile(_files.first);
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
      _editor.text = _store.read(name);
      _dirty = false;
      _savedFlash = false;
    });
    _parse();
  }

  Future<void> _openDirectory() async {
    final path = await _pick();
    if (path == null) return;
    setState(() {
      _store = LessonStore(Directory(path));
      _files = _store.listMarkdown();
      _currentFile = null;
      _editor.clear();
      _dirty = false;
    });
    if (_files.isNotEmpty) {
      _openFile(_files.first);
    } else {
      setState(() {
        _lesson = null;
        _parseError = '这个目录里没有 .md 文件';
      });
    }
  }

  void _save() {
    if (_currentFile == null) return;
    _store.write(_currentFile!, _editor.text);
    setState(() {
      _dirty = false;
      _savedFlash = true;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课时工作台'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _currentFile == null ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_savedFlash ? '已写回正本' : _dirty ? '保存' : '已保存'),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左栏：目录 + 文件 + Markdown 编辑器
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
                          _store.dir.path,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openDirectory,
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('打开课时目录'),
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
                      _parseError == null
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
