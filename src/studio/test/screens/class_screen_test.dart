import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/models/class_teaching.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/screens/class_screen.dart';

Widget createClassTest(CourseDataService service) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: service,
      child: const ClassScreen(),
    ),
  );
}

void main() {
  group('ClassScreen', () {
    testWidgets('shows empty state when no classes', (tester) async {
      final service = CourseDataService();
      await tester.pumpWidget(createClassTest(service));

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('shows class names and status', (tester) async {
      final service = CourseDataService();
      service.classes.addAll([
        ClassTeaching(
          id: 'c1', name: '浙理班级', refName: '大数据微专业',
          refId: 'p1', status: ClassStatus.active,
          startDate: '2026-03-01', endDate: '2026-07-15',
          studentCount: 45, progress: 0.6,
        ),
      ]);

      await tester.pumpWidget(createClassTest(service));

      expect(find.text('浙理班级'), findsOneWidget);
      expect(find.textContaining('大数据微专业'), findsOneWidget);
      expect(find.textContaining('2026-03-01'), findsOneWidget);
    });

    testWidgets('tap class opens detail bottom sheet', (tester) async {
      final service = CourseDataService();
      service.classes.addAll([
        ClassTeaching(
          id: 'c1', name: '浙理班级', refName: '大数据微专业',
          refId: 'p1', status: ClassStatus.active,
          startDate: '2026-03-01', endDate: '2026-07-15',
          studentCount: 45, progress: 0.6,
        ),
      ]);

      await tester.pumpWidget(createClassTest(service));

      // Tap class card
      await tester.tap(find.text('浙理班级'));
      await tester.pumpAndSettle();

      // Detail sheet shows metrics
      expect(find.text('学员数'), findsOneWidget);
      expect(find.text('出勤率'), findsOneWidget);
      expect(find.text('完成率'), findsOneWidget);
    });
  });
}
