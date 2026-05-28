import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../models/category.dart';
import '../models/session.dart';
import '../providers/category_provider.dart';
import '../providers/timer_provider.dart';
import '../services/foreground_task_handler.dart';
import '../services/health_service.dart';
import '../utils/date_utils.dart';
import '../widgets/category_card.dart';
import '../widgets/day_timeline_chart.dart';
import '../widgets/timer_banner.dart';
import '../theme.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  Map<int, int> _totalByCategory = {};
  List<Session> _sessions = [];
  List<({DateTime start, DateTime end})> _sleepSessions = [];
  Timer? _refreshTimer;

  String _sleepLoadedDate = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sleepLoadedDate = ''; // 再取得を強制
      _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final today = getLocalDateString();
    final totals = await getTotalSecByCategory(today);
    final sessions = await getSessionsForDate(today);
    // 睡眠データは日付が変わった時 or 未取得の時のみ取得
    if (_sleepLoadedDate != today) {
      final connected = await isHealthConnected();
      final sleep = connected ? await getSleepForDate(today) : <({DateTime start, DateTime end})>[];
      if (mounted) {
        setState(() {
          _totalByCategory = totals;
          _sessions = sessions;
          _sleepSessions = sleep;
          _sleepLoadedDate = today; // 連携有無にかかわらずロード済みとマーク
        });
      }
    } else if (mounted) {
      setState(() {
        _totalByCategory = totals;
        _sessions = sessions;
      });
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }

  Future<void> _handleTap(Category category) async {
    final timer = ref.read(timerProvider);

    if (timer.activeCategoryId == category.id) {
      await stopForegroundTimer();
      await ref.read(timerProvider.notifier).stop();
    } else {
      if (timer.isActive) {
        await stopForegroundTimer();
        await ref.read(timerProvider.notifier).stop();
      }
      final budgetSec = category.budgetMin * 60;
      await ref.read(timerProvider.notifier).start(category.id!, budgetSec, category.type);
      final updatedTimer = ref.read(timerProvider);
      final startedAt = updatedTimer.startedAt!;
      try {
        await startForegroundTimer(
          categoryName: category.name,
          startedAt: startedAt,
          budgetSec: budgetSec,
          previousTotalSec: updatedTimer.previousTotalSec,
          categoryType: updatedTimer.categoryType,
        );
      } catch (e) {
        debugPrint('ForegroundService error: $e');
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    await _refresh();
  }

  Future<void> _handleStop() async {
    await stopForegroundTimer();
    await ref.read(timerProvider.notifier).stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final timer = ref.watch(timerProvider);
    final today = getLocalDateString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '$today（${weekdayJa()}）',
                style: const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (categories) => Expanded(
                child: Column(
                  children: [
                    if (_sessions.isNotEmpty || _sleepSessions.isNotEmpty) ...[
                      Center(
                        child: DayTimelineChart(
                            sessions: _sessions,
                            categoryColors: {
                              for (final cat in categories)
                                if (cat.id != null) cat.id!: _parseColor(cat.color),
                            },
                            categoryNames: {
                              for (final cat in categories)
                                if (cat.id != null) cat.id!: cat.name,
                            },
                            date: today,
                            sleepSessions: _sleepSessions,
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                    if (timer.isActive && timer.startedAt != null)
                      TimerBanner(
                        categoryName: categories
                            .firstWhere(
                              (c) => c.id == timer.activeCategoryId,
                              orElse: () => categories.isEmpty
                                  ? const Category(
                                      name: '',
                                      type: 'quota',
                                      color: '#64b5f6',
                                      budgetMin: 0,
                                      sortOrder: 0)
                                  : categories.first,
                            )
                            .name,
                        startedAt: timer.startedAt!,
                        onStop: _handleStop,
                        previousTotalSec: timer.previousTotalSec,
                        budgetSec: timer.budgetSec ?? 0,
                        categoryType: timer.categoryType,
                      ),
                    Expanded(
                      child: categories.isEmpty
                          ? const Center(
                              child: Text(
                                '設定画面からカテゴリを追加してください',
                                style: TextStyle(color: AppColors.textSub),
                              ),
                            )
                          : Builder(builder: (_) {
                              final now = DateTime.now();
                              final active = categories
                                  .where((c) => c.isActiveOn(now))
                                  .toList();
                              return ListView.builder(
                                itemCount: active.length,
                                itemBuilder: (context, i) {
                                  final cat = active[i];
                                  return CategoryCard(
                                    category: cat,
                                    totalSec: _totalByCategory[cat.id] ?? 0,
                                    isActive: cat.id == timer.activeCategoryId,
                                    isAnyActive: timer.isActive,
                                    onTap: () => _handleTap(cat),
                                  );
                                },
                              );
                            }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
