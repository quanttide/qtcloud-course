import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/program_service.dart';
import 'services/data_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/program_screen.dart';
import 'screens/class_screen.dart';
import 'widgets/sidebar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  final baseUrl = apiBaseUrl.isNotEmpty ? apiBaseUrl : null;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProgramService(baseUrl: baseUrl)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseDataService(baseUrl: baseUrl)..load(),
        ),
      ],
      child: const QtCloudCourseApp(),
    ),
  );
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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _titles = ['仪表盘', '课程研发', '教学管理'];

  static const _screens = [
    DashboardScreen(),
    ProgramScreen(),
    ClassScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final programService = context.watch<ProgramService>();
    final classService = context.watch<CourseDataService>();
    if (!programService.loaded || !classService.loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: Row(
        children: [
          Sidebar(
            currentIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
