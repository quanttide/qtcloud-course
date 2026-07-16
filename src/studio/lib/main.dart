import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/program_service.dart';
import 'services/data_service.dart';
import 'services/assessment_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/program_screen.dart';
import 'screens/class_screen.dart';
import 'widgets/sidebar.dart';

/// 默认 Provider API 地址。通过环境变量 `API_BASE_URL` 覆盖。
/// 设为空字符串（`API_BASE_URL=`）强制使用本地 JSON 模式。
const _defaultApiBaseUrl = 'http://localhost:8080';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const envUrl = String.fromEnvironment('API_BASE_URL');
  // 未设置时默认走 API；显式设为空时走本地 JSON
  final baseUrl = envUrl.isNotEmpty ? envUrl : (envUrl == '' ? null : _defaultApiBaseUrl);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProgramService(baseUrl: baseUrl)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseDataService(baseUrl: baseUrl)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AssessmentService(baseUrl: baseUrl)..load(),
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

  static const _screens = [DashboardScreen(), ProgramScreen(), ClassScreen()];

  @override
  Widget build(BuildContext context) {
    final programService = context.watch<ProgramService>();
    final classService = context.watch<CourseDataService>();
    final assessmentService = context.watch<AssessmentService>();
    if (!programService.loaded ||
        !classService.loaded ||
        !assessmentService.loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    final fallback = programService.offlineFallback ||
        classService.offlineFallback ||
        assessmentService.offlineFallback;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_titles[_currentIndex]),
            if (fallback) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '离线模式',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Row(
        children: [
          Sidebar(
            currentIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
          ),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}
