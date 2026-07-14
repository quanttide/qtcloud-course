import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/class_teaching.dart';
import '../models/enums.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class CourseDataService extends ChangeNotifier {
  List<ClassTeaching> _classes = [];
  bool _loaded = false;
  String? _error;
  bool _loading = false;

  final String? baseUrl;
  http.Client client;

  /// Mock 学生/教师数据，嵌入在 assets/classes.json 或直接 mock
  final List<Student> _students = [
    Student(id: 'student-1', name: '张三', email: 'zhangsan@example.com'),
    Student(id: 'student-2', name: '李四', email: 'lisi@example.com'),
    Student(id: 'student-3', name: '王五', email: 'wangwu@example.com'),
    Student(id: 'student-4', name: '赵六', email: 'zhaoliu@example.com'),
    Student(id: 'student-5', name: '陈七', email: 'chenqi@example.com'),
  ];

  final List<Teacher> _teachers = [
    Teacher(
      id: 'teacher-1',
      name: '王教授',
      email: 'wang@example.com',
      title: '教授',
    ),
    Teacher(id: 'teacher-2', name: '李老师', email: 'li@example.com', title: '讲师'),
  ];

  List<ClassTeaching> get classes => _classes;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get loading => _loading;

  int get activeClasses =>
      _classes.where((c) => c.status.name == 'active').length;
  int get totalStudents => _classes.fold(0, (sum, c) => sum + c.studentCount);

  CourseDataService({this.baseUrl, http.Client? client})
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
    final jsonStr = await rootBundle.loadString('assets/classes.json');
    final list = json.decode(jsonStr) as List<dynamic>;
    _classes = list
        .map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadFromApi() async {
    final uri = Uri.parse('$baseUrl/classes');
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load classes: ${response.statusCode}');
    }
    final list = json.decode(response.body) as List<dynamic>;
    _classes = list
        .map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- 班级 CRUD ----

  void createClass({
    required String name,
    required String refName,
    required String refId,
    String refType = 'program',
    required String startDate,
    required String endDate,
  }) {
    final newClass = ClassTeaching(
      id: 'class-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      refName: refName,
      refType: refType,
      refId: refId,
      startDate: startDate,
      endDate: endDate,
    );
    _classes = [..._classes, newClass];
    notifyListeners();
  }

  void updateClass(
    String id, {
    String? name,
    String? refName,
    String? refType,
    String? refId,
    ClassStatus? status,
    String? startDate,
    String? endDate,
    int? studentCount,
    double? progress,
    List<String>? teacherIds,
    List<String>? studentIds,
  }) {
    final index = _classes.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final c = _classes[index];
    _classes[index] = c.copyWith(
      name: name,
      refName: refName,
      refType: refType,
      refId: refId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      studentCount: studentCount,
      progress: progress,
      teacherIds: teacherIds,
      studentIds: studentIds,
    );
    _classes = [..._classes];
    notifyListeners();
  }

  void deleteClass(String id) {
    _classes = _classes.where((c) => c.id != id).toList();
    notifyListeners();
  }

  // ---- 学生/教师查询 ----

  List<Student> getStudentsByClass(String classId) {
    final idx = _classes.indexWhere((c) => c.id == classId);
    if (idx == -1) return [];
    return _students
        .where((s) => _classes[idx].studentIds.contains(s.id))
        .toList();
  }

  List<Teacher> getTeachersByClass(String classId) {
    final idx = _classes.indexWhere((c) => c.id == classId);
    if (idx == -1) return [];
    return _teachers
        .where((t) => _classes[idx].teacherIds.contains(t.id))
        .toList();
  }
}
