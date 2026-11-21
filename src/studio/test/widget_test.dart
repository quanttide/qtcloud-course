import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/main.dart';

void main() {
  testWidgets('app smoke test - 工作台两栏渲染', (tester) async {
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
    // 右栏空态提示
    expect(find.text('先打开一个课时，这里就是学员看到的样子'), findsOneWidget);
  });
}
