import 'enums.dart';
import 'program.dart';

class Phase {
  final String id;
  final String name;
  final String description;
  final int sortOrder;
  final ContentStatus status;
  final List<Lesson> lessons;

  const Phase({
    required this.id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    this.status = ContentStatus.draft,
    this.lessons = const [],
  });

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      status: ContentStatus.fromString(json['status'] as String? ?? 'draft'),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Phase copyWith({
    String? id,
    String? name,
    String? description,
    int? sortOrder,
    ContentStatus? status,
    List<Lesson>? lessons,
  }) {
    return Phase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
    );
  }
}
