class Teacher {
  final String id;
  final String name;
  final String email;
  final String? title;

  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.title,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      title: json['title'] as String?,
    );
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? title,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (title != null) 'title': title,
  };
}
