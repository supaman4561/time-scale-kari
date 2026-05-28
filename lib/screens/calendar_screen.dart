import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../providers/category_provider.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart' show getLocalDateString;
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
  Map<String, List<({Color color, bool cleared})>> _categoryDots = {};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Color _parseCatColor(String hex) {
    try {
      return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }

  Future<void> _loadMonth() async {
    final yearMonth =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final categories = ref.read(categoryProvider).valueOrNull ?? [];

    final db = await getDailySessions(yearMonth);

    final statusMap = <String, DayStatus>{};
    final categoryDots = <String, List<({Color color, bool cleared})>>{};
    final todayStr = getLocalDateString();

    for (final entry in db.entries) {
      final dateStr = entry.key;
      final totals = entry.value;
      final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
      final isToday = dateStr == todayStr;
      // アクティブ曜日のカテゴリのみ判定対象
      final activeCats = categories.where((c) => c.isActiveOn(dt)).toList();

      final results = activeCats.map((cat) {
        if (isToday && cat.type == 'limit') return false;
        final totalSec = totals[cat.id] ?? 0;
        return isCategoryCleared(
            type: cat.type, budgetMin: cat.budgetMin, totalSec: totalSec);
      }).toList();

      final cleared = isDayCleared(results);
      statusMap[dateStr] = cleared ? DayStatus.clear : DayStatus.notClear;

      final dots = activeCats.map((cat) {
        if (isToday && cat.type == 'limit') {
          return (color: _parseCatColor(cat.color), cleared: false);
        }
        final totalSec = totals[cat.id] ?? 0;
        final catCleared = isCategoryCleared(
            type: cat.type, budgetMin: cat.budgetMin, totalSec: totalSec);
        return (color: _parseCatColor(cat.color), cleared: catCleared);
      }).toList();
      categoryDots[dateStr] = dots;
    }

    if (mounted) {
      setState(() {
        _statusMap = statusMap;
        _categoryDots = categoryDots;
      });
    }
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
              categoryDots: _categoryDots,
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
