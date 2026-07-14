class Student {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (avatar != null) 'avatar': avatar,
  };
}
