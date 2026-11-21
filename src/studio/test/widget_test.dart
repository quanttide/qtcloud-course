import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/main.dart';

void main() {
  testWidgets('app smoke test - 打开即放示例课时，两栏可见', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const QtCloudCourseApp());
    expect(find.text('课时工作台'), findsOneWidget);
    expect(find.text('打开课时目录'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 示例课时加载后：右栏就是学员端形态，一眼看出这是干什么的
    await tester.pumpAndSettle();
    expect(find.text('示例数据'), findsOneWidget);
    expect(find.text('用 AI 生成你的第一张图'), findsWidgets);
    expect(find.text('复制这句话'), findsWidgets);
  });
}
