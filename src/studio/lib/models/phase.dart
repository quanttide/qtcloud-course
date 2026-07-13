import 'program.dart';

class Phase {
  final String id;
  final String name;
  final int sortOrder;
  final List<Lesson> lessons;

  const Phase({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.lessons = const [],
  });

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Phase copyWith({
    String? id,
    String? name,
    int? sortOrder,
    List<Lesson>? lessons,
  }) {
    return Phase(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      lessons: lessons ?? this.lessons,
    );
  }
}
