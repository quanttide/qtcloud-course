import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/assessment_service.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/screens/assessment_list_screen.dart';

Widget createAssessmentListTest(
  AssessmentService assessmentService, {
  CourseDataService? dataService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: assessmentService),
      ChangeNotifierProvider.value(value: dataService ?? CourseDataService()),
    ],
    child: MaterialApp(
      home: const AssessmentListScreen(classId: 'class-1', className: '测试班级'),
    ),
  );
}

void main() {
  group('AssessmentListScreen', () {
    testWidgets('shows empty state', (tester) async {
      final service = AssessmentService();
      await tester.pumpWidget(createAssessmentListTest(service));

      expect(find.text('暂无考核'), findsOneWidget);
    });

    testWidgets('shows assessment items', (tester) async {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '期中考试',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
        type: AssessmentType.exam,
      );
      service.createAssessment(
        classId: 'class-1',
        title: '课后作业',
        fullScore: 10,
        passScore: 6,
        deadline: '2026-06-15',
      );

      await tester.pumpWidget(createAssessmentListTest(service));

      expect(find.text('期中考试'), findsOneWidget);
      expect(find.text('课后作业'), findsOneWidget);
      expect(find.text('考试'), findsOneWidget);
      expect(find.text('作业'), findsOneWidget);
      expect(find.textContaining('100分'), findsOneWidget);
    });

    testWidgets('tap assessment navigates to detail', (tester) async {
      final service = AssessmentService();
      service.createAssessment(
        classId: 'class-1',
        title: '期中考试',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
        type: AssessmentType.exam,
      );

      await tester.pumpWidget(createAssessmentListTest(service));

      await tester.tap(find.text('期中考试'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Running inside pushed route — detail screen AppBar title
      expect(find.text('期中考试'), findsWidgets);
      expect(find.text('暂无提交'), findsOneWidget);
    });
  });
}
