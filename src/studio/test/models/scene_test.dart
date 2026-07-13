import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/scene.dart';

void main() {
  final stepJson = {'order': 1, 'content': '访问 zed.dev 下载 Zed 编辑器'};

  final choiceJson = {'label': '继续', 'targetSceneId': 'scene-2'};

  final sceneJson = {
    'id': 'scene-1',
    'name': 'zed-setup',
    'title': 'Zed 的安装与初始化',
    'steps': [stepJson],
    'choices': [choiceJson],
    'verifyTip': 'Zed 编辑器能正常编辑即完成',
  };

  group('Step', () {
    test('fromJson parses all fields', () {
      final step = Step.fromJson(stepJson);
      expect(step.order, 1);
      expect(step.content, '访问 zed.dev 下载 Zed 编辑器');
    });

    test('copyWith overrides fields', () {
      final step = Step.fromJson(stepJson);
      final copy = step.copyWith(order: 2);
      expect(copy.order, 2);
      expect(copy.content, step.content);
    });
  });

  group('Choice', () {
    test('fromJson parses all fields', () {
      final choice = Choice.fromJson(choiceJson);
      expect(choice.label, '继续');
      expect(choice.targetSceneId, 'scene-2');
    });

    test('copyWith overrides fields', () {
      final choice = Choice.fromJson(choiceJson);
      final copy = choice.copyWith(label: '跳过');
      expect(copy.label, '跳过');
      expect(copy.targetSceneId, choice.targetSceneId);
    });
  });

  group('Scene', () {
    test('fromJson parses all fields', () {
      final scene = Scene.fromJson(sceneJson);
      expect(scene.id, 'scene-1');
      expect(scene.name, 'zed-setup');
      expect(scene.title, 'Zed 的安装与初始化');
      expect(scene.steps.length, 1);
      expect(scene.choices.length, 1);
      expect(scene.verifyTip, 'Zed 编辑器能正常编辑即完成');
    });

    test('fromJson uses defaults for missing fields', () {
      final scene = Scene.fromJson({'id': 's-1', 'name': 'test'});
      expect(scene.title, '');
      expect(scene.steps, isEmpty);
      expect(scene.choices, isEmpty);
      expect(scene.verifyTip, '');
    });

    test('copyWith overrides specified fields', () {
      final scene = Scene.fromJson(sceneJson);
      final copy = scene.copyWith(title: '新场景');
      expect(copy.title, '新场景');
      expect(copy.id, scene.id);
    });
  });
}
