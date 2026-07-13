import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/scene.dart';
import 'package:qtcloud_course_studio/models/program.dart';
import 'package:qtcloud_course_studio/screens/preview_screen.dart';

final _scenes = [
  Scene(
    id: 's1',
    name: 'zed-setup',
    title: 'Zed 的安装与初始化',
    steps: [
      Step(order: 1, content: '访问 zed.dev 下载 Zed'),
      Step(order: 2, content: '安装并打开 Zed'),
    ],
    choices: [Choice(label: '继续', targetSceneId: 's2')],
    verifyTip: 'Zed 能正常编辑即完成',
  ),
  Scene(
    id: 's2',
    name: 'deepseek-auth',
    title: '注册并获取 DeepSeek 密钥',
    steps: [
      Step(order: 1, content: '访问 DeepSeek 官网'),
      Step(order: 2, content: '创建新密钥并复制'),
    ],
    choices: [Choice(label: '继续', targetSceneId: 's3')],
    verifyTip: '密钥已复制',
  ),
  Scene(
    id: 's3',
    name: 'configure-zed',
    title: '配置密钥',
    steps: [
      Step(order: 1, content: '打开 Zed Agent'),
      Step(order: 2, content: '填入密钥'),
    ],
    choices: [],
    verifyTip: '输入 hello 测试回复',
  ),
];

final _lesson = Lesson(
  id: 'l1',
  title: '开发环境搭建',
  duration: 30,
  scenes: _scenes,
);

Widget createTestApp({Lesson? lesson}) {
  return MaterialApp(
    home: PreviewScreen(
      lessonId: lesson?.id ?? 'l1',
      lesson: lesson ?? _lesson,
    ),
  );
}

void main() {
  group('PreviewScreen', () {
    testWidgets('显示课时标题和第一场景', (tester) async {
      await tester.pumpWidget(createTestApp());

      // AppBar 标题
      expect(find.text('开发环境搭建'), findsOneWidget);

      // 左侧：视频场景名
      expect(find.text('Zed 的安装与初始化'), findsWidgets);

      // 右侧：操作步骤面板
      expect(find.text('操作步骤'), findsOneWidget);

      // 步骤列表
      expect(find.text('访问 zed.dev 下载 Zed'), findsOneWidget);
      expect(find.text('安装并打开 Zed'), findsOneWidget);

      // 验证提示
      expect(find.textContaining('验证：'), findsOneWidget);

      // 继续按钮
      expect(find.text('继续 →'), findsOneWidget);
    });

    testWidgets('场景导航列出所有场景', (tester) async {
      await tester.pumpWidget(createTestApp());

      // 三个场景都在导航中
      expect(find.text('Zed 的安装与初始化'), findsWidgets);
      expect(find.text('注册并获取 DeepSeek 密钥'), findsOneWidget);
      expect(find.text('配置密钥'), findsOneWidget);
    });

    testWidgets('点击继续切换到下一个场景', (tester) async {
      await tester.pumpWidget(createTestApp());

      // 在第一场景
      expect(find.text('访问 zed.dev 下载 Zed'), findsOneWidget);

      // 点击继续
      await tester.tap(find.text('继续 →'));
      await tester.pumpAndSettle();

      // 切换到第二场景
      expect(find.text('访问 DeepSeek 官网'), findsOneWidget);
      expect(find.text('创建新密钥并复制'), findsOneWidget);
      expect(find.textContaining('密钥已复制'), findsOneWidget);
    });

    testWidgets('依次切换到最后场景显示完成按钮', (tester) async {
      await tester.pumpWidget(createTestApp());

      // 第一场景 → 第二场景
      await tester.tap(find.text('继续 →'));
      await tester.pumpAndSettle();

      // 第二场景 → 第三场景
      await tester.tap(find.text('继续 →'));
      await tester.pumpAndSettle();

      // 第三场景：显示"完成课时"而不是"继续"
      expect(find.text('继续 →'), findsNothing);
      expect(find.text('完成课时 🎉'), findsOneWidget);
      expect(find.text('打开 Zed Agent'), findsOneWidget);
      expect(find.textContaining('输入 hello 测试回复'), findsOneWidget);
      expect(find.textContaining('验证：'), findsOneWidget);
    });

    testWidgets('点击完成课时显示完成页', (tester) async {
      await tester.pumpWidget(createTestApp());

      // 一路切换到第三场景
      await tester.tap(find.text('继续 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续 →'));
      await tester.pumpAndSettle();

      // 点击完成
      await tester.tap(find.text('完成课时 🎉'));
      await tester.pumpAndSettle();

      // 完成页
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('课时完成'), findsOneWidget);
      expect(find.textContaining('你已完成「开发环境搭建」的所有场景。'), findsOneWidget);

      // 步骤面板不再显示
      expect(find.text('操作步骤'), findsNothing);
    });

    testWidgets('点击场景导航直接跳转', (tester) async {
      await tester.pumpWidget(createTestApp());

      // 点击导航中的第三场景
      await tester.tap(find.text('配置密钥'));
      await tester.pumpAndSettle();

      // 直接显示第三场景内容
      expect(find.text('打开 Zed Agent'), findsOneWidget);
      expect(find.text('填入密钥'), findsOneWidget);
    });
  });
}
