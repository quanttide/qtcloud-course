import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/program.dart';
import '../models/class_teaching.dart';

class CourseDataService extends ChangeNotifier {
  List<Program> _programs = [];
  List<ClassTeaching> _classes = [];
  final Map<String, Lesson> _lessonCache = {};
  bool _loaded = false;

  List<Program> get programs => _programs;
  List<ClassTeaching> get classes => _classes;
  bool get loaded => _loaded;

  int get totalPrograms => _programs.length;
  int get totalCourses =>
      _programs.fold(0, (sum, p) => sum + p.courses.length);
  int get totalLessons => _programs.fold(
      0, (sum, p) => sum + p.courses.fold(0, (s, c) => s + c.phases.fold(0, (s2, ph) => s2 + ph.lessons.length)));
  int get activeClasses =>
      _classes.where((c) => c.status.name == 'active').length;
  int get totalStudents =>
      _classes.fold(0, (sum, c) => sum + c.studentCount);

  void markLoaded() {
    _loaded = true;
    notifyListeners();
  }

  Future<void> load() async {
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
    _loaded = true;
    notifyListeners();
  }

  Future<Lesson?> loadLesson(String lessonId) async {
    if (_lessonCache.containsKey(lessonId)) return _lessonCache[lessonId];

    try {
      final jsonStr = await rootBundle.loadString('assets/$lessonId.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final lesson = Lesson.fromJson(data);
      _lessonCache[lessonId] = lesson;
      return lesson;
    } catch (_) {
      return null;
    }
  }
}
