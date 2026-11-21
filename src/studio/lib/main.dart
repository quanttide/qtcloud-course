import 'package:flutter/material.dart';
import 'screens/workbench_screen.dart';

/// 量潮课程云 Studio：单页工作台，左写课时、右看学员端形态。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QtCloudCourseApp());
}

class QtCloudCourseApp extends StatelessWidget {
  const QtCloudCourseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮课程云',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WorkbenchScreen(),
    );
  }
}
