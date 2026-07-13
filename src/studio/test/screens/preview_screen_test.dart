import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/screens/preview_screen.dart';

void main() {
  group('PreviewScreen', () {
    testWidgets('renders lesson id', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PreviewScreen(lessonId: 'lesson-1')),
      );

      expect(find.text('试听'), findsOneWidget);
      expect(find.textContaining('lesson-1'), findsOneWidget);
    });
  });
}
