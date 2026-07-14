import 'enums.dart';

class ClassTeaching {
  final String id;
  final String name;
  final String refName;
  final String refType;
  final String refId;
  final ClassStatus status;
  final String startDate;
  final String endDate;
  final int studentCount;
  final double progress;

  const ClassTeaching({
    required this.id,
    required this.name,
    required this.refName,
    this.refType = 'program',
    required this.refId,
    this.status = ClassStatus.preparing,
    required this.startDate,
    required this.endDate,
    this.studentCount = 0,
    this.progress = 0.0,
  });

  factory ClassTeaching.fromJson(Map<String, dynamic> json) {
    return ClassTeaching(
      id: json['id'] as String,
      name: json['name'] as String,
      refName: json['refName'] as String,
      refType: json['refType'] as String? ?? 'program',
      refId: json['refId'] as String,
      status: ClassStatus.fromString(json['status'] as String? ?? 'preparing'),
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      studentCount: json['studentCount'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ClassTeaching copyWith({
    String? id,
    String? name,
    String? refName,
    String? refType,
    String? refId,
    ClassStatus? status,
    String? startDate,
    String? endDate,
    int? studentCount,
    double? progress,
  }) {
    return ClassTeaching(
      id: id ?? this.id,
      name: name ?? this.name,
      refName: refName ?? this.refName,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      studentCount: studentCount ?? this.studentCount,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'refName': refName,
    'refType': refType,
    'refId': refId,
    'status': status.name,
    'startDate': startDate,
    'endDate': endDate,
    'studentCount': studentCount,
    'progress': progress,
  };
}
