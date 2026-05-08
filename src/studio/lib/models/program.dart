import 'enums.dart';

class Lesson {
  final String id;
  final String title;
  final String description;
  final int duration;
  final ContentStatus status;

  const Lesson({
    required this.id,
    required this.title,
    this.description = '',
    this.duration = 45,
    this.status = ContentStatus.draft,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as int? ?? 45,
      status: ContentStatus.fromString(json['status'] as String? ?? 'draft'),
    );
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    int? duration,
    ContentStatus? status,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }
}

class Course {
  final String id;
  final String name;
  final String description;
  final ContentStatus status;
  final List<Lesson> lessons;

  const Course({
    required this.id,
    required this.name,
    this.description = '',
    this.status = ContentStatus.draft,
    this.lessons = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: ContentStatus.fromString(json['status'] as String? ?? 'draft'),
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Course copyWith({
    String? id,
    String? name,
    String? description,
    ContentStatus? status,
    List<Lesson>? lessons,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
    );
  }
}

class Program {
  final String id;
  final String name;
  final String description;
  final ContentStatus status;
  final List<Course> courses;

  const Program({
    required this.id,
    required this.name,
    this.description = '',
    this.status = ContentStatus.draft,
    this.courses = const [],
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: ContentStatus.fromString(json['status'] as String? ?? 'draft'),
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Program copyWith({
    String? id,
    String? name,
    String? description,
    ContentStatus? status,
    List<Course>? courses,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      courses: courses ?? this.courses,
    );
  }
}
