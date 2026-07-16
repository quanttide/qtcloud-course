import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import '../models/assessment.dart';
import '../models/submission.dart';

class AssessmentService extends ChangeNotifier {
  List<Assessment> _assessments = [];
  List<Submission> _submissions = [];
  bool _loaded = false;
  String? _error;
  bool _loading = false;
  bool _offlineFallback = false;

  final String? baseUrl;
  http.Client client;

  List<Assessment> get assessments => _assessments;
  List<Submission> get submissions => _submissions;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get loading => _loading;
  bool get offlineFallback => _offlineFallback;
  bool get isApiMode => baseUrl != null;

  AssessmentService({this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  void markLoaded() {
    _loaded = true;
    notifyListeners();
  }

  List<Assessment> getAssessmentsByClass(String classId) {
    return _assessments.where((a) => a.classId == classId).toList();
  }

  List<Submission> getSubmissions(String assessmentId) {
    return _submissions.where((s) => s.assessmentId == assessmentId).toList();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _offlineFallback = false;
    notifyListeners();
    try {
      if (baseUrl != null) {
        try {
          await _loadFromApi();
        } catch (e) {
          debugPrint('API load failed ($e), falling back to local JSON');
          _offlineFallback = true;
          try {
            await _loadFromAssets();
          } catch (e2) {
            debugPrint('Fallback assets also failed: $e2');
          }
        }
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
    try {
      final assessStr = await rootBundle.loadString('assets/assessments.json');
      _assessments = (json.decode(assessStr) as List<dynamic>)
          .map((e) => Assessment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load assessments: $e');
    }
    try {
      final subStr = await rootBundle.loadString('assets/submissions.json');
      _submissions = (json.decode(subStr) as List<dynamic>)
          .map((e) => Submission.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load submissions: $e');
    }
  }

  Future<void> _loadFromApi() async {
    final assessUri = Uri.parse('$baseUrl/assessments');
    final assessResp = await client.get(assessUri);
    if (assessResp.statusCode != 200) {
      throw Exception('Failed to load assessments: ${assessResp.statusCode}');
    }
    final assessList = json.decode(assessResp.body) as List<dynamic>;
    _assessments = assessList
        .map((e) => Assessment.fromJson(e as Map<String, dynamic>))
        .toList();

    final subUri = Uri.parse('$baseUrl/submissions');
    final subResp = await client.get(subUri);
    if (subResp.statusCode != 200) {
      throw Exception('Failed to load submissions: ${subResp.statusCode}');
    }
    final subList = json.decode(subResp.body) as List<dynamic>;
    _submissions = subList
        .map((e) => Submission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static const _uuid = Uuid();
  String _nextId() => _uuid.v4();

  // ── API Sync Helpers ──

  void _apiPost(String path, Map<String, dynamic> body) {
    if (baseUrl == null) return;
    unawaited(
      client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .then((_) {})
          .catchError((_) {}),
    );
  }

  void _apiPut(String path, Map<String, dynamic> body) {
    if (baseUrl == null) return;
    unawaited(
      client
          .put(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .then((_) {})
          .catchError((_) {}),
    );
  }

  void _apiDelete(String path) {
    if (baseUrl == null) return;
    unawaited(
      client.delete(Uri.parse('$baseUrl$path')).then((_) {}).catchError((_) {}),
    );
  }

  // ---- 考核 CRUD ----

  void createAssessment({
    required String classId,
    required String title,
    required int fullScore,
    required int passScore,
    required String deadline,
    AssessmentType type = AssessmentType.homework,
  }) {
    final assessment = Assessment(
      id: _nextId(),
      classId: classId,
      type: type,
      title: title,
      fullScore: fullScore,
      passScore: passScore,
      deadline: deadline,
    );
    _assessments = [..._assessments, assessment];
    _apiPost('/assessments', assessment.toJson());
    notifyListeners();
  }

  void updateAssessment(
    String id, {
    String? title,
    AssessmentType? type,
    int? fullScore,
    int? passScore,
    String? deadline,
  }) {
    final index = _assessments.indexWhere((a) => a.id == id);
    if (index == -1) return;
    _assessments[index] = _assessments[index].copyWith(
      title: title,
      type: type,
      fullScore: fullScore,
      passScore: passScore,
      deadline: deadline,
    );
    _assessments = [..._assessments];
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (type != null) body['type'] = type.name;
    if (fullScore != null) body['fullScore'] = fullScore;
    if (passScore != null) body['passScore'] = passScore;
    if (deadline != null) body['deadline'] = deadline;
    _apiPut('/assessments/$id', body);
    notifyListeners();
  }

  void deleteAssessment(String id) {
    _assessments = _assessments.where((a) => a.id != id).toList();
    _submissions = _submissions.where((s) => s.assessmentId != id).toList();
    _apiDelete('/assessments/$id');
    notifyListeners();
  }

  // ---- 评分操作 ----

  void scoreSubmission(String submissionId, double score, String? comment) {
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index == -1) return;
    _submissions[index] = _submissions[index].copyWith(
      score: score,
      comment: comment,
    );
    _submissions = [..._submissions];
    _apiPut('/submissions/$submissionId', {
      'score': score,
      // ignore: use_null_aware_elements
      if (comment != null) 'comment': comment,
    });
    notifyListeners();
  }
}
