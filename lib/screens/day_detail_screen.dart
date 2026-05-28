import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../models/session.dart';
import '../providers/category_provider.dart';
import '../services/health_service.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import '../widgets/day_timeline_chart.dart';
import '../widgets/progress_bar.dart';
import '../theme.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final String date;

  const DayDetailScreen({super.key, required this.date});

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  Map<int, int> _totals = {};
  List<Session> _sessions = [];
  List<({DateTime start, DateTime end})> _sleepSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await getTotalSecByCategory(widget.date);
    final sessions = await getSessionsForDate(widget.date);
    final connected = await isHealthConnected();
    final sleep = connected ? await getSleepForDate(widget.date) : <({DateTime start, DateTime end})>[];
    if (mounted) {
      setState(() {
        _totals = totals;
        _sessions = sessions;
        _sleepSessions = sleep;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final dt = DateTime.tryParse(widget.date) ?? DateTime.now();
    final label = '${widget.date}（${weekdayJa(dt)}）';
    // limit型は当日終了後にクリア判定
    final isToday = widget.date == getLocalDateString();

    return Scaffold(
      appBar: AppBar(
        title: Text(label, style: const TextStyle(fontSize: 15)),
        backgroundColor: AppColors.card,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(child: Text('カテゴリがありません'));
                }
                return Column(
                  children: [
                    if (_sessions.isNotEmpty || _sleepSessions.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                            date: widget.date,
                            sleepSessions: _sleepSessions,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: categories.length,
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final totalSec = _totals[cat.id] ?? 0;
                          final budgetMin = cat.budgetMin;
                          final cleared = !isToday || cat.type != 'limit'
                              ? isCategoryCleared(
                                  type: cat.type,
                                  budgetMin: budgetMin,
                                  totalSec: totalSec,
                                )
                              : false;
                          final dotColor = _parseColor(cat.color);
                          final budgetSec = budgetMin * 60;
                          final progress = budgetMin > 0
                              ? cat.type == 'limit'
                                  ? (budgetSec - totalSec).clamp(0, budgetSec) / budgetSec
                                  : totalSec / budgetSec
                              : 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: cleared
                                  ? Border.all(color: AppColors.green.withAlpha(100))
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: dotColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: dotColor.withAlpha(160), blurRadius: 6)],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(cat.name,
                                      style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600))),
                                    if (cleared)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withAlpha(40),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: const Text('CLEAR',
                                          style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat.type == 'limit'
                                          ? '残り ${formatDuration((budgetSec - totalSec).clamp(0, budgetSec))}'
                                          : '${formatDuration(totalSec)} / ${formatDuration(budgetSec)}',
                                      style: const TextStyle(color: AppColors.textSub, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ProgressBar(progress: progress, color: dotColor),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
