import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/screens/workbench_screen.dart';
import 'package:qtcloud_course_studio/services/lesson_store.dart';
import 'package:qtcloud_course_studio/widgets/lesson_preview.dart';

/// 只在右栏（预览）里找——左栏编辑器里是同一段原文
Finder previewText(String text) => find.descendant(
      of: find.byType(LessonPreview),
      matching: find.text(text),
    );

const _md = '''
# 用 AI 生成你的第一张图

四步做完，你就学会一套「让 AI 教自己」的方法。

## 把提示词发给元宝

复制下面这一句。

```copy 点按钮一键复制
用刚才那段提示词，直接生成一张图片。
```
''';

void main() {
  late Directory tempDir;
  late LessonStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('workbench_test');
    File('${tempDir.path}/01-hello-world.md').writeAsStringSync(_md);
    store = openLessonStore(tempDir.path);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<void> pumpWorkbench(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkbenchScreen(
          initialStore: store,
          pickDirectory: () async => tempDir.path,
        ),
      ),
    );
  }

  testWidgets('打开目录后左栏是正本 Markdown，右栏是学员端预览', (tester) async {
    await pumpWorkbench(tester);

    expect(find.text('01-hello-world.md'), findsWidgets);
    expect(previewText('用 AI 生成你的第一张图'), findsOneWidget);
    expect(previewText('把提示词发给元宝'), findsOneWidget);
    expect(previewText('用刚才那段提示词，直接生成一张图片。'), findsOneWidget);
  });

  testWidgets('改一句，右侧预览当场跟着变', (tester) async {
    await pumpWorkbench(tester);

    await tester.enterText(
      find.byType(TextField),
      _md.replaceFirst('用刚才那段提示词，直接生成一张图片。', '改后的指令'),
    );
    await tester.pump();

    expect(previewText('改后的指令'), findsOneWidget);
    expect(previewText('用刚才那段提示词，直接生成一张图片。'), findsNothing);
  });

  testWidgets('保存写回正本文件', (tester) async {
    await pumpWorkbench(tester);

    await tester.enterText(find.byType(TextField), '# 新标题\n\n## 步骤\n\n动作\n');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.text('已写回正本'), findsOneWidget);
    expect(
      File('${tempDir.path}/01-hello-world.md').readAsStringSync(),
      '# 新标题\n\n## 步骤\n\n动作\n',
    );
  });

  testWidgets('解析报错时右栏不装作没事', (tester) async {
    await pumpWorkbench(tester);

    await tester.enterText(find.byType(TextField), '没有标题的正文');
    await tester.pump();

    expect(find.text('缺少以 # 开头的课时标题'), findsOneWidget);
    expect(find.byType(LessonPreview), findsNothing);
    expect(find.text('解析失败，右侧不出预览——报错在左栏下方'), findsOneWidget);
  });
}
