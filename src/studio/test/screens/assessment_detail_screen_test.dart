import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/models/assessment.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/assessment_service.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/screens/assessment_detail_screen.dart';

Widget createAssessmentDetailTest(Assessment assessment,
    {AssessmentService? assessmentService,
    CourseDataService? dataService}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(
        value: assessmentService ?? AssessmentService(),
      ),
      ChangeNotifierProvider.value(
        value: dataService ?? CourseDataService(),
      ),
    ],
    child: MaterialApp(
      home: AssessmentDetailScreen(assessment: assessment),
    ),
  );
}

void main() {
  group('AssessmentDetailScreen', () {
    testWidgets('shows assessment info', (tester) async {
      final assessment = Assessment(
        id: 'a1',
        classId: 'class-1',
        type: AssessmentType.exam,
        title: '期中考试',
        fullScore: 100,
        passScore: 60,
        deadline: '2026-07-01',
      );
      final service = AssessmentService();

      await tester.pumpWidget(
          createAssessmentDetailTest(assessment, assessmentService: service));

      expect(find.text('考试'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
      expect(find.textContaining('60'), findsOneWidget);
      expect(find.text('2026-07-01'), findsOneWidget);
      expect(find.text('提交列表 (0)'), findsOneWidget);
    });

    testWidgets('shows no submissions message', (tester) async {
      final assessment = Assessment(
        id: 'a1',
        classId: 'class-1',
        type: AssessmentType.homework,
        title: '作业一',
        fullScore: 10,
        passScore: 6,
        deadline: '2026-07-01',
      );
      final service = AssessmentService();

      await tester.pumpWidget(
          createAssessmentDetailTest(assessment, assessmentService: service));

      expect(find.text('暂无提交'), findsOneWidget);
    });
  });
}
