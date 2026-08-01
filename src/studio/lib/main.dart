import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/program_service.dart';
import 'screens/program_screen.dart';
import 'widgets/sidebar.dart';

/// 默认本地模式。设 `API_BASE_URL` 环境变量可切回 Provider API 模式。
const _defaultApiBaseUrl = null;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const envUrl = String.fromEnvironment('API_BASE_URL');
  final baseUrl = envUrl.isNotEmpty ? envUrl : _defaultApiBaseUrl;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProgramService(baseUrl: baseUrl)..load(),
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
  static const _titles = ['课程研发'];

  static const _screens = [ProgramScreen()];

  @override
  Widget build(BuildContext context) {
    final programService = context.watch<ProgramService>();
    if (!programService.loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_titles[0]),
            if (programService.offlineFallback) ...[
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
            currentIndex: 0,
            onDestinationSelected: (_) {},
          ),
          Expanded(
            child: IndexedStack(index: 0, children: _screens),
          ),
        ],
      ),
    );
  }
}
