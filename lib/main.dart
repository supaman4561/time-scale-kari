import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db/schema.dart';
import 'providers/category_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'services/foreground_task_handler.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initForegroundTask();
  await initNotifications();
  await getDb();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeScale',
      theme: buildAppTheme(),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    TodayScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(timerProvider.notifier).restore();
      final timer = ref.read(timerProvider);
      if (timer.isActive && timer.startedAt != null) {
        final cats = ref.read(categoryProvider).valueOrNull ?? [];
        if (cats.isEmpty) return;
        final cat = cats.firstWhere(
          (c) => c.id == timer.activeCategoryId,
          orElse: () => cats.first,
        );
        try {
          await startForegroundTimer(
            categoryName: cat.name,
            startedAt: timer.startedAt!,
            budgetSec: timer.budgetSec ?? 0,
          );
        } catch (e) {
          debugPrint('ForegroundService restore error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'TODAY'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'CALENDAR'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETTINGS'),
        ],
      ),
    );
  }
}
