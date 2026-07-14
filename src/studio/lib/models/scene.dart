class Step {
  final int order;
  final String content;

  const Step({required this.order, required this.content});

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      order: json['order'] as int,
      content: json['content'] as String,
    );
  }

  Step copyWith({int? order, String? content}) {
    return Step(
      order: order ?? this.order,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() => {'order': order, 'content': content};
}

class Choice {
  final String label;
  final String targetSceneId;

  const Choice({required this.label, required this.targetSceneId});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      label: json['label'] as String,
      targetSceneId: json['targetSceneId'] as String,
    );
  }

  Choice copyWith({String? label, String? targetSceneId}) {
    return Choice(
      label: label ?? this.label,
      targetSceneId: targetSceneId ?? this.targetSceneId,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'targetSceneId': targetSceneId};
}

class Scene {
  final String id;
  final String name;
  final String title;
  final List<Step> steps;
  final List<Choice> choices;
  final String verifyTip;
  final String videoUrl;

  const Scene({
    required this.id,
    required this.name,
    this.title = '',
    this.steps = const [],
    this.choices = const [],
    this.verifyTip = '',
    this.videoUrl = '',
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => Step.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => Choice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      verifyTip: json['verifyTip'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
    );
  }

  Scene copyWith({
    String? id,
    String? name,
    String? title,
    List<Step>? steps,
    List<Choice>? choices,
    String? verifyTip,
    String? videoUrl,
  }) {
    return Scene(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      steps: steps ?? this.steps,
      choices: choices ?? this.choices,
      verifyTip: verifyTip ?? this.verifyTip,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'steps': steps.map((s) => s.toJson()).toList(),
    'choices': choices.map((c) => c.toJson()).toList(),
    'verifyTip': verifyTip,
    'videoUrl': videoUrl,
  };
}
