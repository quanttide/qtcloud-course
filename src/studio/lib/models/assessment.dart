import 'enums.dart';

class Assessment {
  final String id;
  final String classId;
  final AssessmentType type;
  final String title;
  final int fullScore;
  final int passScore;
  final String deadline;

  const Assessment({
    required this.id,
    required this.classId,
    required this.type,
    required this.title,
    required this.fullScore,
    required this.passScore,
    required this.deadline,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] as String,
      classId: json['classId'] as String,
      type: AssessmentType.fromString(json['type'] as String? ?? 'homework'),
      title: json['title'] as String,
      fullScore: (json['fullScore'] as num).toInt(),
      passScore: (json['passScore'] as num).toInt(),
      deadline: json['deadline'] as String,
    );
  }

  Assessment copyWith({
    String? id,
    String? classId,
    AssessmentType? type,
    String? title,
    int? fullScore,
    int? passScore,
    String? deadline,
  }) {
    return Assessment(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      type: type ?? this.type,
      title: title ?? this.title,
      fullScore: fullScore ?? this.fullScore,
      passScore: passScore ?? this.passScore,
      deadline: deadline ?? this.deadline,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'type': type.name,
    'title': title,
    'fullScore': fullScore,
    'passScore': passScore,
    'deadline': deadline,
  };
}
