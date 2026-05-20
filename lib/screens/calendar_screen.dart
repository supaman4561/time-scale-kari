import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../providers/category_provider.dart';
import '../utils/clear_check.dart';
import '../widgets/calendar_grid.dart';
import '../theme.dart';
import 'day_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime.now();
  Map<String, DayStatus> _statusMap = {};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final yearMonth =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final categories = ref.read(categoryProvider).valueOrNull ?? [];

    final db = await getDailySessions(yearMonth);

    final statusMap = <String, DayStatus>{};

    for (final entry in db.entries) {
      final dateStr = entry.key;
      final totals = entry.value;
      final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
      final isWeekendDay =
          dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

      final results = categories.map((cat) {
        final budgetMin =
            isWeekendDay ? cat.weekendBudgetMin : cat.weekdayBudgetMin;
        final totalSec = totals[cat.id] ?? 0;
        return isCategoryCleared(
            type: cat.type, budgetMin: budgetMin, totalSec: totalSec);
      }).toList();

      final cleared = isDayCleared(results);
      statusMap[dateStr] = cleared ? DayStatus.clear : DayStatus.notClear;
    }

    if (mounted) setState(() => _statusMap = statusMap);
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
    _loadMonth();
  }

  void _nextMonth() {
    setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textSub),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_month.year}年 ${_month.month}月',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textSub),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            CalendarGrid(
              month: _month,
              statusMap: _statusMap,
              onDayTap: (date) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayDetailScreen(date: date),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
