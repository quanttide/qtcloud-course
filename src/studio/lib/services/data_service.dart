import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/program.dart';
import '../models/class_teaching.dart';

class CourseDataService extends ChangeNotifier {
  List<Program> _programs = [];
  List<ClassTeaching> _classes = [];
  final Map<String, Lesson> _lessonCache = {};
  bool _loaded = false;
  String? _error;
  bool _loading = false;

  final String? baseUrl;
  http.Client client;

  List<Program> get programs => _programs;
  List<ClassTeaching> get classes => _classes;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get loading => _loading;

  int get totalPrograms => _programs.length;
  int get totalCourses =>
      _programs.fold(0, (sum, p) => sum + p.courses.length);
  int get totalLessons => _programs.fold(
      0, (sum, p) => sum + p.courses.fold(0, (s, c) => s + c.phases.fold(0, (s2, ph) => s2 + ph.lessons.length)));
  int get activeClasses =>
      _classes.where((c) => c.status.name == 'active').length;
  int get totalStudents =>
      _classes.fold(0, (sum, c) => sum + c.studentCount);

  CourseDataService({this.baseUrl, http.Client? client}) : client = client ?? http.Client();

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
    final programsJson =
        await rootBundle.loadString('assets/programs.json');
    final classesJson =
        await rootBundle.loadString('assets/classes.json');

    final programsList = json.decode(programsJson) as List<dynamic>;
    final classesList = json.decode(classesJson) as List<dynamic>;

    _programs = programsList
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
    _classes = classesList
        .map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadFromApi() async {
    final programsUri = Uri.parse('$baseUrl/programs');
    final classesUri = Uri.parse('$baseUrl/classes');

    List<dynamic> programsList;
    List<dynamic> classesList;

    try {
      final programsResponse = await client.get(programsUri);
      if (programsResponse.statusCode != 200) {
        throw Exception('Failed to load programs: ${programsResponse.statusCode}');
      }
      programsList = json.decode(programsResponse.body) as List<dynamic>;
    } catch (e) {
      debugPrint('Failed to load programs: $e');
      rethrow;
    }

    try {
      final classesResponse = await client.get(classesUri);
      if (classesResponse.statusCode != 200) {
        throw Exception('Failed to load classes: ${classesResponse.statusCode}');
      }
      classesList = json.decode(classesResponse.body) as List<dynamic>;
    } catch (e) {
      debugPrint('Failed to load classes: $e');
      rethrow;
    }

    _programs = programsList
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
    _classes = classesList
        .map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Lesson?> loadLesson(String lessonId) async {
    if (_lessonCache.containsKey(lessonId)) return _lessonCache[lessonId];

    try {
      if (baseUrl != null) {
        return await _loadLessonFromApi(lessonId);
      } else {
        return await _loadLessonFromAssets(lessonId);
      }
    } catch (e) {
      debugPrint('Failed to load lesson $lessonId: $e');
      return null;
    }
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
}
