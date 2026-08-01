import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/program_service.dart';
import 'package:qtcloud_course_studio/main.dart';

void main() {
  testWidgets('app smoke test - renders main shell', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final ps = ProgramService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ps),
        ],
        child: const QtCloudCourseApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    ps.markLoaded();
    await tester.pumpAndSettle();

    expect(find.text('课程研发'), findsWidgets);
  });
}
