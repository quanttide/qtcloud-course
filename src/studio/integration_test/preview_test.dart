import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:qtcloud_course_studio/services/data_service.dart';
import 'package:qtcloud_course_studio/models/program.dart';
import 'package:qtcloud_course_studio/models/phase.dart';
import 'package:qtcloud_course_studio/models/enums.dart';
import 'package:qtcloud_course_studio/screens/program_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('从课程研发页展开树 → 点击试听 → 跳转预览页', (tester) async {
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
              Phase(
                id: 'ph1',
                name: '基础阶段',
                sortOrder: 1,
                lessons: [
                  Lesson(
                    id: 'l1',
                    title: '数据工程概述',
                    duration: 45,
                    status: ContentStatus.published,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ]);
    service.markLoaded();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(home: ProgramScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 展开 Program
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.text('数据工程'), findsOneWidget);

    // 展开 Course
    await tester.tap(find.byIcon(Icons.expand_more).last);
    await tester.pumpAndSettle();
    expect(find.text('基础阶段'), findsOneWidget);

    // 展开 Phase
    await tester.tap(find.byIcon(Icons.expand_more).last);
    await tester.pumpAndSettle();
    expect(find.text('数据工程概述'), findsOneWidget);

    // 点击试听按钮
    await tester.tap(find.byIcon(Icons.headphones));
    await tester.pumpAndSettle();

    // 验证跳转到预览页
    expect(find.text('试听'), findsOneWidget);
    expect(find.textContaining('l1'), findsOneWidget);
  });
}
