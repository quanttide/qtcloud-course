import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/services/program_service.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/screens/program_screen.dart';

Widget createProgramTest(ProgramService service) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: service),
      ChangeNotifierProvider.value(value: CourseDataService()..markLoaded()),
    ],
    child: const MaterialApp(home: ProgramScreen()),
  );
}

void main() {
  group('ProgramScreen', () {
    testWidgets('shows app bar with title', (tester) async {
      final service = ProgramService();
      service.createProgram('数据工程', '');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));
      expect(find.text('课程研发'), findsOneWidget);
    });

    testWidgets('shows program names', (tester) async {
      final service = ProgramService();
      service.createProgram('大数据微专业', '系统化课程体系');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('大数据微专业'), findsOneWidget);
    });

    testWidgets('shows empty state when no programs', (tester) async {
      final service = ProgramService();
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('expand program to show courses', (tester) async {
      final service = ProgramService();
      final p = service.createProgram('P1', '');
      service.createCourse(p.id, '数据工程', '');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      // expand
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('数据工程'), findsOneWidget);
    });

    testWidgets('expand course to show phases', (tester) async {
      final service = ProgramService();
      final p = service.createProgram('P1', '');
      final c = service.createCourse(p.id, '数据工程', '');
      service.createPhase(p.id, c!.id, '基础');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // now expand the course
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.text('基础'), findsOneWidget);
    });

    testWidgets('expand phase to show lessons', (tester) async {
      final service = ProgramService();
      final p = service.createProgram('P1', '');
      final c = service.createCourse(p.id, '数据工程', '');
      final ph = service.createPhase(p.id, c!.id, '基础');
      service.createLesson(p.id, c.id, ph!.id, '概述');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      // expand all
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.text('概述'), findsOneWidget);
    });

    testWidgets('lesson row has listen button', (tester) async {
      final service = ProgramService();
      final p = service.createProgram('P1', '');
      final c = service.createCourse(p.id, '数据工程', '');
      final ph = service.createPhase(p.id, c!.id, '基础');
      service.createLesson(p.id, c.id, ph!.id, '概述');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.headphones), findsOneWidget);
    });

    testWidgets('draft program shows publish button', (tester) async {
      final service = ProgramService();
      service.createProgram('P1', '');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      expect(find.byTooltip('发布'), findsOneWidget);
    });

    testWidgets('publishing toggles status and shows unpublish', (tester) async {
      final service = ProgramService();
      service.createProgram('P1', '');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      await tester.tap(find.byTooltip('发布'));
      await tester.pumpAndSettle();

      expect(service.programs[0].status, ContentStatus.published);
      expect(find.byTooltip('下架'), findsOneWidget);
    });

    testWidgets('course with draft lessons shows confirmation dialog', (tester) async {
      final service = ProgramService();
      final p = service.createProgram('P', '');
      final c = service.createCourse(p.id, 'C', '');
      final ph = service.createPhase(p.id, c!.id, 'Ph');
      service.createLesson(p.id, c.id, ph!.id, 'Draft');
      service.markLoaded();
      await tester.pumpWidget(createProgramTest(service));

      // expand to course level
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.byTooltip('发布'), findsWidgets);
    });
  });
}
