import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/widgets/sidebar.dart';

void main() {
  testWidgets('renders all three navigation items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Sidebar(
            currentIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('仪表盘'), findsOneWidget);
    expect(find.text('课程研发'), findsOneWidget);
    expect(find.text('教学管理'), findsOneWidget);
    expect(find.byIcon(Icons.dashboard), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.byIcon(Icons.group), findsOneWidget);
  });

  testWidgets('highlights current item and fires onTap', (tester) async {
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Sidebar(
            currentIndex: 1,
            onDestinationSelected: (i) => selected = i,
          ),
        ),
      ),
    );

    // index 1 → 课程研发
    await tester.tap(find.text('课程研发'));
    expect(selected, 1);

    await tester.tap(find.text('教学管理'));
    expect(selected, 2);
  });
}
