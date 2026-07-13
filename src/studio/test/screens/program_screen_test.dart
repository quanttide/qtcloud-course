import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/models/program.dart';
import 'package:qtcloud_course_studio/models/phase.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/screens/program_screen.dart';

Widget createProgramTest(CourseDataService service) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: service,
      child: const ProgramScreen(),
    ),
  );
}

void main() {
  group('ProgramScreen', () {
    testWidgets('shows app bar with title', (tester) async {
      final service = CourseDataService();
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('课程研发'), findsOneWidget);
    });

    testWidgets('shows program names', (tester) async {
      final service = CourseDataService();
      service.programs.addAll([
        Program(id: 'p1', name: '大数据微专业', status: ContentStatus.published),
        Program(id: 'p2', name: 'AI应用开发', status: ContentStatus.draft),
      ]);
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('大数据微专业'), findsOneWidget);
      expect(find.text('AI应用开发'), findsOneWidget);
    });

    testWidgets('shows empty state when no programs', (tester) async {
      final service = CourseDataService();
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('expand program to show courses', (tester) async {
      final service = CourseDataService();
      service.programs.addAll([
        Program(
          id: 'p1',
          name: '大数据微专业',
          status: ContentStatus.published,
          courses: [
            Course(id: 'c1', name: '数据工程', status: ContentStatus.published),
          ],
        ),
      ]);
      await tester.pumpWidget(createProgramTest(service));

      expect(find.text('数据工程'), findsNothing);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('数据工程'), findsOneWidget);
    });

    testWidgets('expand course to show phases', (tester) async {
      final service = CourseDataService();
      service.programs.addAll([
        Program(
          id: 'p1',
          name: '大数据微专业',
          status: ContentStatus.published,
          courses: [
            Course(
              id: 'c1',
              name: '数据工程',
              status: ContentStatus.published,
              phases: [
                Phase(id: 'ph1', name: '基础阶段', sortOrder: 1),
              ],
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(createProgramTest(service));

      // Expand program
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.text('基础阶段'), findsNothing);

      // Expand course
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.text('基础阶段'), findsOneWidget);
    });

    testWidgets('expand phase to show lessons', (tester) async {
      final service = CourseDataService();
      service.programs.addAll([
        Program(
          id: 'p1',
          name: '大数据微专业',
          status: ContentStatus.published,
          courses: [
            Course(
              id: 'c1',
              name: '数据工程',
              status: ContentStatus.published,
              phases: [
                Phase(id: 'ph1', name: '基础阶段', sortOrder: 1, lessons: [
                  Lesson(id: 'l1', title: '数据工程概述', duration: 45),
                ]),
              ],
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(createProgramTest(service));

      // Expand program
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Expand course
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.text('数据工程概述'), findsNothing);

      // Expand phase
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.text('数据工程概述'), findsOneWidget);
    });

    testWidgets('lesson row has listen button', (tester) async {
      final service = CourseDataService();
      service.programs.addAll([
        Program(
          id: 'p1',
          name: '大数据微专业',
          status: ContentStatus.published,
          courses: [
            Course(
              id: 'c1',
              name: '数据工程',
              status: ContentStatus.published,
              phases: [
                Phase(id: 'ph1', name: '基础阶段', sortOrder: 1, lessons: [
                  Lesson(id: 'l1', title: '数据工程概述', duration: 45),
                ]),
              ],
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(createProgramTest(service));

      // Expand all the way to lesson
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.headphones), findsOneWidget);
    });
  });
}
