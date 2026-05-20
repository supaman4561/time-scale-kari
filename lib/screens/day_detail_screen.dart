import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../providers/category_provider.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await getTotalSecByCategory(widget.date);
    if (mounted) setState(() { _totals = totals; _loading = false; });
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
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final totalSec = _totals[cat.id] ?? 0;
                    final isWeekendDay = dt.weekday == DateTime.saturday ||
                        dt.weekday == DateTime.sunday;
                    final budgetMin = isWeekendDay
                        ? cat.weekendBudgetMin
                        : cat.weekdayBudgetMin;
                    final cleared = isCategoryCleared(
                      type: cat.type,
                      budgetMin: budgetMin,
                      totalSec: totalSec,
                    );
                    final dotColor = _parseColor(cat.color);
                    final progress = budgetMin > 0 ? totalSec / (budgetMin * 60) : 0.0;

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
                              Text('${totalSec ~/ 60}分 / $budgetMin分',
                                style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ProgressBar(progress: progress, color: dotColor),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
