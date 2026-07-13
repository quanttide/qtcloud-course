import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app启动 - 加载后显示主导航并支持页面切换', (tester) async {
    final service = CourseDataService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: const app.QtCloudCourseApp(),
      ),
    );

    // 初始加载中
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.markLoaded();
    await tester.pumpAndSettle();

    // 主导航显示
    expect(find.text('仪表盘'), findsWidgets);
    expect(find.text('课程研发'), findsOneWidget);
    expect(find.text('教学管理'), findsOneWidget);

    // 切换到课程研发
    await tester.tap(find.text('课程研发'));
    await tester.pumpAndSettle();
    expect(find.text('暂无数据'), findsOneWidget);

    // 切换到教学管理
    await tester.tap(find.text('教学管理'));
    await tester.pumpAndSettle();
    expect(find.text('暂无数据'), findsOneWidget);

    // 切回仪表盘
    await tester.tap(find.text('仪表盘'));
    await tester.pumpAndSettle();
    expect(find.text('专业数'), findsOneWidget);
  });
}
