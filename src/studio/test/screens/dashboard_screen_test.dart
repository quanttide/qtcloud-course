import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/models/program.dart';
import 'package:qtcloud_course_studio/models/class_teaching.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/screens/dashboard_screen.dart';

Widget createDashboardTest(CourseDataService service) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: service,
      child: const Scaffold(body: DashboardScreen()),
    ),
  );
}

CourseDataService createServiceWithData() {
  final service = CourseDataService();
  service.programs.addAll([
    Program(
      id: 'prog-1',
      name: '大数据微专业',
      description: '系统化课程体系',
      status: ContentStatus.published,
      courses: [
        Course(
          id: 'course-1',
          name: '数据工程',
          status: ContentStatus.published,
          lessons: [
            Lesson(id: 'l1', title: '数据工程概述', status: ContentStatus.published),
            Lesson(id: 'l2', title: '数据采集技术', status: ContentStatus.published),
            Lesson(id: 'l3', title: '数据清洗', status: ContentStatus.draft),
          ],
        ),
        Course(
          id: 'course-2',
          name: 'Python基础',
          status: ContentStatus.published,
          lessons: [
            Lesson(id: 'l4', title: '环境搭建', status: ContentStatus.published),
            Lesson(id: 'l5', title: '变量与类型', status: ContentStatus.published),
            Lesson(id: 'l6', title: '控制流', status: ContentStatus.draft),
          ],
        ),
      ],
    ),
    Program(
      id: 'prog-2',
      name: 'AI应用开发',
      status: ContentStatus.draft,
      courses: [
        Course(
          id: 'course-3',
          name: '机器学习入门',
          status: ContentStatus.draft,
          lessons: [
            Lesson(id: 'l7', title: '概述', status: ContentStatus.draft),
            Lesson(id: 'l8', title: '线性回归', status: ContentStatus.draft),
          ],
        ),
      ],
    ),
    Program(
      id: 'prog-3',
      name: 'UI/UX设计',
      status: ContentStatus.draft,
      courses: [],
    ),
  ]);
  service.classes.addAll([
    ClassTeaching(
      id: 'c1', name: '浙理班级', refName: '大数据微专业',
      refId: 'prog-1', status: ClassStatus.active,
      startDate: '2026-03-01', endDate: '2026-07-15',
      studentCount: 45, progress: 0.6,
    ),
    ClassTeaching(
      id: 'c2', name: '杭电班级', refName: 'Python基础',
      refId: 'course-2', status: ClassStatus.preparing,
      startDate: '2026-05-10', endDate: '2026-08-20',
      studentCount: 32, progress: 0.0,
    ),
    ClassTeaching(
      id: 'c3', name: '线上周末班', refName: '大数据微专业',
      refId: 'prog-1', status: ClassStatus.active,
      startDate: '2026-04-05', endDate: '2026-10-30',
      studentCount: 78, progress: 0.35,
    ),
    ClassTeaching(
      id: 'c4', name: '暑期集训营', refName: 'AI应用开发',
      refId: 'prog-2', status: ClassStatus.preparing,
      startDate: '2026-07-01', endDate: '2026-08-30',
      studentCount: 24, progress: 0.0,
    ),
  ]);
  return service;
}

void main() {
  group('DashboardScreen', () {
    testWidgets('displays title and metric cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final service = createServiceWithData();
      await tester.pumpWidget(createDashboardTest(service));

      expect(find.text('仪表盘'), findsOneWidget);
      expect(find.text('专业数'), findsOneWidget);
      expect(find.text('课程数'), findsOneWidget);
      expect(find.text('课时数'), findsOneWidget);
      expect(find.text('进行中班级'), findsOneWidget);
      expect(find.text('学员数'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      expect(find.text('179'), findsOneWidget);
    });

    testWidgets('shows program and class lists', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final service = createServiceWithData();
      await tester.pumpWidget(createDashboardTest(service));

      expect(find.text('专业列表'), findsOneWidget);
      expect(find.text('班级列表'), findsOneWidget);
      expect(find.text('大数据微专业'), findsOneWidget);
      expect(find.text('浙理班级'), findsOneWidget);
    });

    testWidgets('shows 查看全部 buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final service = createServiceWithData();
      await tester.pumpWidget(createDashboardTest(service));

      expect(find.text('查看全部 →'), findsNWidgets(2));
    });
  });
}
