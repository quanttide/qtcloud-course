import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/lesson.dart';
import 'package:qtcloud_course_studio/widgets/lesson_preview.dart';

/// 与 lite 课时页同结构的小样例
Lesson _lesson() => const Lesson(
      title: '总裁查岗：一句话摸清家底',
      lede: '不用开会、不用问人——发一句话，让 AI 去公开网站上替你查。',
      steps: [
        LessonStep(
          num: 1,
          title: '打开工具，粘贴下面这句话',
          doText: '这是总裁的指令——告诉 AI 去哪两个网站、采什么、写成什么。',
          blocks: [
            CopyBlock(
              label: '点按钮一键复制',
              text: '用刚才那段提示词，直接生成一张图片。',
            ),
            NoteBlock(label: '做完你会看到', lines: ['输入框里出现上面那段话']),
          ],
        ),
        LessonStep(
          num: 2,
          title: '等 AI 去两个网站采集',
          doText: '它会打开网页、读取文字和数字。',
          blocks: [
            CodeBlock(
              label: '做完你会看到',
              lines: [CodeLine('› 正在访问 game.quanttide.com/tycoon'), CodeLine('✓ 采集完成', ok: true)],
            ),
          ],
        ),
      ],
      tip: '注意"查不到的信息"那一栏。',
      foot: '从"做出来"扩展到"看清楚"',
    );

void main() {
  // 课时页是长列表，视口加高让课末提示进屏
  Future<void> pumpPreview(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('预览渲染页眉、步骤与课末提示', (tester) async {
    await pumpPreview(tester, LessonPreview(lesson: _lesson()));(MaterialApp(home: Scaffold(body: LessonPreview(lesson: _lesson()))));

    expect(find.text('总裁查岗：一句话摸清家底'), findsOneWidget);
    expect(find.text('不用开会、不用问人——发一句话，让 AI 去公开网站上替你查。'), findsOneWidget);
    expect(find.text('打开工具，粘贴下面这句话'), findsOneWidget);
    expect(find.text('等 AI 去两个网站采集'), findsOneWidget);
    expect(find.text('注意"查不到的信息"那一栏。'), findsOneWidget);
    expect(find.text('从"做出来"扩展到"看清楚"'), findsOneWidget);
    expect(find.text('课时内容与教程仓同源，改动以教程仓为准。'), findsOneWidget);
  });

  testWidgets('步骤序号与五种块的标签逐字可见', (tester) async {
    await pumpPreview(tester, LessonPreview(lesson: _lesson()));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('点按钮一键复制'), findsOneWidget);
    expect(find.text('用刚才那段提示词，直接生成一张图片。'), findsOneWidget);
    expect(find.text('输入框里出现上面那段话'), findsOneWidget);
    expect(find.text('✓ 采集完成'), findsOneWidget);
    expect(find.text('复制这句话'), findsOneWidget);
  });

  testWidgets('点复制后按钮变成已复制', (tester) async {
    await pumpPreview(tester, LessonPreview(lesson: _lesson()));

    await tester.tap(find.text('复制这句话'));
    await tester.pump();
    await tester.pump();

    expect(find.text('已复制，去粘贴吧'), findsOneWidget);
  });
}
