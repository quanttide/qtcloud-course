import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/models/class_teaching.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/program_service.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/services/assessment_service.dart';
import 'package:qtcloud_course_studio/screens/dashboard_screen.dart';

Widget createDashboardTest(
    ProgramService ps, CourseDataService cs, AssessmentService as) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: ps),
      ChangeNotifierProvider.value(value: cs),
      ChangeNotifierProvider.value(value: as),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
}

AssessmentService createAssessmentService() {
  final service = AssessmentService();
  service.markLoaded();
  return service;
}

ProgramService createProgramService() {
  final service = ProgramService();
  service.createProgram('大数据微专业', '系统化课程体系');
  service.markLoaded();
  return service;
}

CourseDataService createClassService() {
  final service = CourseDataService();
  service.classes.addAll([
    ClassTeaching(id: '1', name: '2026春1班', refName: '大数据微专业', refId: 'P1', status: ClassStatus.active, startDate: '2026-03-01', endDate: '2026-06-30', studentCount: 28),
    ClassTeaching(id: '2', name: '2026春2班', refName: '大数据微专业', refId: 'P1', status: ClassStatus.active, startDate: '2026-03-01', endDate: '2026-06-30', studentCount: 32),
  ]);
  service.markLoaded();
  return service;
}

void main() {
  testWidgets('displays title and metric cards', (tester) async {
    final ps = createProgramService();
    final cs = createClassService();
    final as = createAssessmentService();
    await tester.pumpWidget(createDashboardTest(ps, cs, as));

    expect(find.text('仪表盘'), findsWidgets);
    expect(find.text('专业数'), findsOneWidget);
    expect(find.text('课程数'), findsOneWidget);
    expect(find.text('课时数'), findsOneWidget);
    expect(find.text('进行中班级'), findsOneWidget);
    expect(find.text('学员数'), findsOneWidget);
    expect(find.text('待评分考核'), findsOneWidget);
  });

  testWidgets('shows program and class lists', (tester) async {
    final ps = createProgramService();
    final cs = createClassService();
    final as = createAssessmentService();
    await tester.pumpWidget(createDashboardTest(ps, cs, as));

    expect(find.text('专业列表'), findsOneWidget);
    expect(find.text('班级列表'), findsOneWidget);
    expect(find.text('大数据微专业'), findsWidgets);
    expect(find.text('2026春1班'), findsOneWidget);
    expect(find.text('2026春2班'), findsOneWidget);
  });

  testWidgets('shows 查看全部 buttons', (tester) async {
    final ps = createProgramService();
    final cs = createClassService();
    final as = createAssessmentService();
    await tester.pumpWidget(createDashboardTest(ps, cs, as));

    expect(find.text('查看全部 →'), findsNWidgets(2));
  });
}
