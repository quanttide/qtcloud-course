import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/enums.dart';
import '../models/program.dart';
import '../models/phase.dart';

class ProgramService extends ChangeNotifier {
  List<Program> _programs = [];
  final Map<String, Lesson> _lessonCache = {};
  bool _loaded = false;
  String? _error;
  bool _loading = false;

  final String? baseUrl;
  http.Client client;

  List<Program> get programs => _programs;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get loading => _loading;

  int get totalPrograms => _programs.length;
  int get totalCourses =>
      _programs.fold(0, (sum, p) => sum + p.courses.length);
  int get totalLessons => _programs.fold(
      0, (sum, p) => sum + p.courses.fold(0, (s, c) => s + c.phases.fold(0, (s2, ph) => s2 + ph.lessons.length)));

  ProgramService({this.baseUrl, http.Client? client}) : client = client ?? http.Client();

  void markLoaded() {
    _loaded = true;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (baseUrl != null) {
        await _loadFromApi();
      } else {
        await _loadFromAssets();
      }
      _loaded = true;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadFromAssets() async {
    final jsonStr = await rootBundle.loadString('assets/programs.json');
    final list = json.decode(jsonStr) as List<dynamic>;
    _programs = list.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _loadFromApi() async {
    final uri = Uri.parse('$baseUrl/programs');
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load programs: ${response.statusCode}');
    }
    final list = json.decode(response.body) as List<dynamic>;
    _programs = list.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
  }

  Lesson? _findLessonInTree(String lessonId) {
    for (final p in _programs) {
      for (final c in p.courses) {
        for (final ph in c.phases) {
          for (final l in ph.lessons) {
            if (l.id == lessonId) return l;
          }
        }
      }
    }
    return null;
  }

  Future<Lesson?> loadLesson(String lessonId) async {
    if (_lessonCache.containsKey(lessonId)) return _lessonCache[lessonId];
    final inTree = _findLessonInTree(lessonId);
    if (inTree != null && inTree.scenes.isNotEmpty) return inTree;
    try {
      if (baseUrl != null) {
        return await _loadLessonFromApi(lessonId);
      } else {
        return await _loadLessonFromAssets(lessonId);
      }
    } catch (e) {
      debugPrint('Failed to load lesson $lessonId: $e');
    }
    return inTree;
  }

  Future<Lesson?> _loadLessonFromAssets(String lessonId) async {
    final jsonStr = await rootBundle.loadString('assets/$lessonId.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final lesson = Lesson.fromJson(data);
    _lessonCache[lessonId] = lesson;
    return lesson;
  }

  Future<Lesson?> _loadLessonFromApi(String lessonId) async {
    final uri = Uri.parse('$baseUrl/lessons/$lessonId');
    final response = await client.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    final lesson = Lesson.fromJson(data);
    _lessonCache[lessonId] = lesson;
    return lesson;
  }

  int _idCounter = 0;
  String _nextId() => '${++_idCounter}';

  // ── Program CRUD ──

  Program createProgram(String name, String description) {
    final program = Program(id: _nextId(), name: name, description: description);
    _programs.add(program);
    notifyListeners();
    return program;
  }

  void updateProgram(String id, {String? name, String? description, ContentStatus? status}) {
    final i = _programs.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _programs[i] = _programs[i].copyWith(name: name, description: description, status: status);
    notifyListeners();
  }

  void deleteProgram(String id) {
    _programs.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ── Course CRUD ──

  Course? createCourse(String programId, String name, String description) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return null;
    final program = _programs[pi];
    final course = Course(id: _nextId(), name: name, description: description, sortOrder: program.courses.length);
    _programs[pi] = program.copyWith(courses: [...program.courses, course]);
    notifyListeners();
    return course;
  }

  void updateCourse(String programId, String courseId, {String? name, String? description, ContentStatus? status, int? sortOrder}) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final updated = program.courses[ci].copyWith(name: name, description: description, status: status, sortOrder: sortOrder);
    final courses = [...program.courses];
    courses[ci] = updated;
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
  }

  void deleteCourse(String programId, String courseId) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    _programs[pi] = program.copyWith(courses: program.courses.where((c) => c.id != courseId).toList());
    notifyListeners();
  }

  // ── Phase CRUD ──

  Phase? createPhase(String programId, String courseId, String name) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return null;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return null;
    final course = program.courses[ci];
    final phase = Phase(id: _nextId(), name: name, sortOrder: course.phases.length);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: [...course.phases, phase]);
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
    return phase;
  }

  void updatePhase(String programId, String courseId, String phaseId, {String? name, String? description, ContentStatus? status, int? sortOrder}) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return;
    final updated = course.phases[phi].copyWith(name: name, description: description, status: status, sortOrder: sortOrder);
    final phases = [...course.phases];
    phases[phi] = updated;
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
  }

  void deletePhase(String programId, String courseId, String phaseId) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: course.phases.where((ph) => ph.id != phaseId).toList());
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
  }

  // ── Lesson CRUD ──

  Lesson? createLesson(String programId, String courseId, String phaseId, String title) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return null;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return null;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return null;
    final phase = course.phases[phi];
    final lesson = Lesson(id: _nextId(), title: title, sortOrder: phase.lessons.length);
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: [...phase.lessons, lesson]);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
    return lesson;
  }

  void updateLesson(String programId, String courseId, String phaseId, String lessonId, {String? title, String? description, ContentStatus? status, int? sortOrder, int? duration}) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return;
    final phase = course.phases[phi];
    final li = phase.lessons.indexWhere((l) => l.id == lessonId);
    if (li == -1) return;
    final updated = phase.lessons[li].copyWith(title: title, description: description, status: status, sortOrder: sortOrder, duration: duration);
    final lessons = [...phase.lessons];
    lessons[li] = updated;
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: lessons);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
  }

  void deleteLesson(String programId, String courseId, String phaseId, String lessonId) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return;
    final phase = course.phases[phi];
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: phase.lessons.where((l) => l.id != lessonId).toList());
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    notifyListeners();
  }

  // ── Import / Export ──

  String exportProgramsJson() {
    final data = {'programs': _programs.map((p) => p.toJson()).toList()};
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String?> importProgramsFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return File(path).readAsString();
  }

  bool mergeProgramsFromJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final list = data['programs'] as List<dynamic>;
      final incoming = list.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
      for (final p in incoming) {
        final i = _programs.indexWhere((e) => e.id == p.id);
        if (i == -1) { _programs.add(p); } else { _programs[i] = p; }
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> exportProgramsToFile() async {
    final outputDir = await FilePicker.platform.getDirectoryPath();
    if (outputDir == null) return false;
    final file = File('$outputDir/programs_export.json');
    await file.writeAsString(exportProgramsJson());
    return true;
  }
}
