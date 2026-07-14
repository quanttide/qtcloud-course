import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/class_teaching.dart';

class CourseDataService extends ChangeNotifier {
  List<ClassTeaching> _classes = [];
  bool _loaded = false;
  String? _error;
  bool _loading = false;

  final String? baseUrl;
  http.Client client;

  List<ClassTeaching> get classes => _classes;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get loading => _loading;

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
    final jsonStr = await rootBundle.loadString('assets/classes.json');
    final list = json.decode(jsonStr) as List<dynamic>;
    _classes = list.map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _loadFromApi() async {
    final uri = Uri.parse('$baseUrl/classes');
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load classes: ${response.statusCode}');
    }
    final list = json.decode(response.body) as List<dynamic>;
    _classes = list.map((e) => ClassTeaching.fromJson(e as Map<String, dynamic>)).toList();
  }
}
