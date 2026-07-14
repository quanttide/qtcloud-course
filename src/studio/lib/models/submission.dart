import 'enums.dart';

class Submission {
  final String id;
  final String assessmentId;
  final String studentId;
  final SubmissionStatus status;
  final double? score;
  final String? comment;
  final String submittedAt;

  const Submission({
    required this.id,
    required this.assessmentId,
    required this.studentId,
    this.status = SubmissionStatus.submitted,
    this.score,
    this.comment,
    required this.submittedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      assessmentId: json['assessmentId'] as String,
      studentId: json['studentId'] as String,
      status: SubmissionStatus.fromString(json['status'] as String? ?? 'submitted'),
      score: (json['score'] as num?)?.toDouble(),
      comment: json['comment'] as String?,
      submittedAt: json['submittedAt'] as String,
    );
  }

  Submission copyWith({
    String? id,
    String? assessmentId,
    String? studentId,
    SubmissionStatus? status,
    double? score,
    String? comment,
    String? submittedAt,
  }) {
    return Submission(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assessmentId': assessmentId,
    'studentId': studentId,
    'status': status.name,
    if (score != null) 'score': score,
    if (comment != null) 'comment': comment,
    'submittedAt': submittedAt,
  };
}
