import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
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
  int get totalCourses => _programs.fold(0, (sum, p) => sum + p.courses.length);
  int get totalLessons => _programs.fold(
    0,
    (sum, p) =>
        sum +
        p.courses.fold(
          0,
          (s, c) => s + c.phases.fold(0, (s2, ph) => s2 + ph.lessons.length),
        ),
  );

  ProgramService({this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

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
    _programs = list
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadFromApi() async {
    final uri = Uri.parse('$baseUrl/programs');
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load programs: ${response.statusCode}');
    }
    final list = json.decode(response.body) as List<dynamic>;
    _programs = list
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
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

  // ── API Sync Helpers ──

  Future<void> _apiPost(String path, Map<String, dynamic> body) async {
    if (baseUrl == null) return;
    try {
      await client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } catch (e) {
      debugPrint('API POST $path failed: $e');
    }
  }

  Future<void> _apiPut(String path, Map<String, dynamic> body) async {
    if (baseUrl == null) return;
    try {
      await client.put(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } catch (e) {
      debugPrint('API PUT $path failed: $e');
    }
  }

  Future<void> _apiDelete(String path) async {
    if (baseUrl == null) return;
    try {
      await client.delete(Uri.parse('$baseUrl$path'));
    } catch (e) {
      debugPrint('API DELETE $path failed: $e');
    }
  }

  static const _uuid = Uuid();
  String _nextId() => _uuid.v4();

  // ── Program CRUD ──

  Program createProgram(String name, String description) {
    final program = Program(
      id: _nextId(),
      name: name,
      description: description,
    );
    _programs.add(program);
    _apiPost('/programs', program.toJson());
    notifyListeners();
    return program;
  }

  void updateProgram(
    String id, {
    String? name,
    String? description,
    ContentStatus? status,
  }) {
    final i = _programs.indexWhere((p) => p.id == id);
    if (i == -1) return;
    _programs[i] = _programs[i].copyWith(
      name: name,
      description: description,
      status: status,
    );
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    _apiPut('/programs/$id', body);
    notifyListeners();
  }

  void deleteProgram(String id) {
    _programs.removeWhere((p) => p.id == id);
    _apiDelete('/programs/$id');
    notifyListeners();
  }

  // ── Course CRUD ──

  Course? createCourse(String programId, String name, String description) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return null;
    final program = _programs[pi];
    final course = Course(
      id: _nextId(),
      name: name,
      description: description,
      sortOrder: program.courses.length,
    );
    _programs[pi] = program.copyWith(courses: [...program.courses, course]);
    _apiPost('/courses', {...course.toJson(), 'programId': programId});
    notifyListeners();
    return course;
  }

  void updateCourse(
    String programId,
    String courseId, {
    String? name,
    String? description,
    ContentStatus? status,
    int? sortOrder,
  }) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final updated = program.courses[ci].copyWith(
      name: name,
      description: description,
      status: status,
      sortOrder: sortOrder,
    );
    final courses = [...program.courses];
    courses[ci] = updated;
    _programs[pi] = program.copyWith(courses: courses);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    _apiPut('/courses/$courseId', body);
    notifyListeners();
  }

  void deleteCourse(String programId, String courseId) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    _programs[pi] = program.copyWith(
      courses: program.courses.where((c) => c.id != courseId).toList(),
    );
    _apiDelete('/courses/$courseId');
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
    final phase = Phase(
      id: _nextId(),
      name: name,
      sortOrder: course.phases.length,
    );
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: [...course.phases, phase]);
    _programs[pi] = program.copyWith(courses: courses);
    _apiPost('/phases', {...phase.toJson(), 'courseId': courseId});
    notifyListeners();
    return phase;
  }

  void updatePhase(
    String programId,
    String courseId,
    String phaseId, {
    String? name,
    String? description,
    ContentStatus? status,
    int? sortOrder,
  }) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return;
    final updated = course.phases[phi].copyWith(
      name: name,
      description: description,
      status: status,
      sortOrder: sortOrder,
    );
    final phases = [...course.phases];
    phases[phi] = updated;
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    _apiPut('/phases/$phaseId', body);
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
    courses[ci] = course.copyWith(
      phases: course.phases.where((ph) => ph.id != phaseId).toList(),
    );
    _programs[pi] = program.copyWith(courses: courses);
    _apiDelete('/phases/$phaseId');
    notifyListeners();
  }

  // ── Lesson CRUD ──

  Lesson? createLesson(
    String programId,
    String courseId,
    String phaseId,
    String title,
  ) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return null;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return null;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return null;
    final phase = course.phases[phi];
    final lesson = Lesson(
      id: _nextId(),
      title: title,
      sortOrder: phase.lessons.length,
    );
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: [...phase.lessons, lesson]);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    _apiPost('/lessons', {...lesson.toJson(), 'phaseId': phaseId});
    notifyListeners();
    return lesson;
  }

  void updateLesson(
    String programId,
    String courseId,
    String phaseId,
    String lessonId, {
    String? title,
    String? description,
    ContentStatus? status,
    int? sortOrder,
    int? duration,
  }) {
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
    final updated = phase.lessons[li].copyWith(
      title: title,
      description: description,
      status: status,
      sortOrder: sortOrder,
      duration: duration,
    );
    final lessons = [...phase.lessons];
    lessons[li] = updated;
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: lessons);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (duration != null) body['duration'] = duration;
    _apiPut('/lessons/$lessonId', body);
    notifyListeners();
  }

  void deleteLesson(
    String programId,
    String courseId,
    String phaseId,
    String lessonId,
  ) {
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
    phases[phi] = phase.copyWith(
      lessons: phase.lessons.where((l) => l.id != lessonId).toList(),
    );
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    _apiDelete('/lessons/$lessonId');
    notifyListeners();
  }

  // ── Reorder ──

  void reorderProgram(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final p = _programs.removeAt(oldIndex);
    _programs.insert(newIndex, p);
    notifyListeners();
  }

  void reorderCourses(String programId, int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final courses = [...program.courses];
    final c = courses.removeAt(oldIndex);
    courses.insert(newIndex, c);
    _programs[pi] = program.copyWith(courses: courses);
    for (int i = 0; i < courses.length; i++) {
      if (courses[i].sortOrder != i) {
        updateCourse(programId, courses[i].id, sortOrder: i);
      }
    }
    notifyListeners();
  }

  void reorderPhases(
    String programId,
    String courseId,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex == newIndex) return;
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phases = [...course.phases];
    final ph = phases.removeAt(oldIndex);
    phases.insert(newIndex, ph);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    for (int i = 0; i < phases.length; i++) {
      if (phases[i].sortOrder != i) {
        updatePhase(programId, courseId, phases[i].id, sortOrder: i);
      }
    }
    notifyListeners();
  }

  void reorderLessons(
    String programId,
    String courseId,
    String phaseId,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex == newIndex) return;
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return;
    final program = _programs[pi];
    final ci = program.courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return;
    final course = program.courses[ci];
    final phi = course.phases.indexWhere((ph) => ph.id == phaseId);
    if (phi == -1) return;
    final phase = course.phases[phi];
    final lessons = [...phase.lessons];
    final l = lessons.removeAt(oldIndex);
    lessons.insert(newIndex, l);
    final phases = [...course.phases];
    phases[phi] = phase.copyWith(lessons: lessons);
    final courses = [...program.courses];
    courses[ci] = course.copyWith(phases: phases);
    _programs[pi] = program.copyWith(courses: courses);
    for (int i = 0; i < lessons.length; i++) {
      if (lessons[i].sortOrder != i) {
        updateLesson(programId, courseId, phaseId, lessons[i].id, sortOrder: i);
      }
    }
    notifyListeners();
  }

  // ── Publish / Unpublish ──

  void publishProgram(String id) {
    updateProgram(id, status: ContentStatus.published);
  }

  void unpublishProgram(String id) {
    updateProgram(id, status: ContentStatus.draft);
  }

  void publishCourse(String programId, String courseId) {
    updateCourse(programId, courseId, status: ContentStatus.published);
  }

  void unpublishCourse(String programId, String courseId) {
    updateCourse(programId, courseId, status: ContentStatus.draft);
  }

  void publishLesson(
    String programId,
    String courseId,
    String phaseId,
    String lessonId,
  ) {
    updateLesson(
      programId,
      courseId,
      phaseId,
      lessonId,
      status: ContentStatus.published,
    );
  }

  void unpublishLesson(
    String programId,
    String courseId,
    String phaseId,
    String lessonId,
  ) {
    updateLesson(
      programId,
      courseId,
      phaseId,
      lessonId,
      status: ContentStatus.draft,
    );
  }

  int draftLessonCountInCourse(String programId, String courseId) {
    final pi = _programs.indexWhere((p) => p.id == programId);
    if (pi == -1) return 0;
    final ci = _programs[pi].courses.indexWhere((c) => c.id == courseId);
    if (ci == -1) return 0;
    return _programs[pi].courses[ci].phases.fold<int>(
      0,
      (sum, ph) =>
          sum + ph.lessons.where((l) => l.status == ContentStatus.draft).length,
    );
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
      final incoming = list
          .map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final p in incoming) {
        final i = _programs.indexWhere((e) => e.id == p.id);
        if (i == -1) {
          _programs.add(p);
        } else {
          _programs[i] = p;
        }
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
