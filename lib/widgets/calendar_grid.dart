import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

enum DayStatus { clear, notClear, noData, today }

class CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, DayStatus> statusMap;
  final void Function(String date) onDayTap;
  final Map<String, List<({Color color, bool cleared})>>? categoryDots;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.statusMap,
    required this.onDayTap,
    this.categoryDots,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = getLocalDateString();
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;

    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final cells = <Widget>[
      for (final label in ['月', '火', '水', '木', '金', '土', '日'])
        Center(
          child: Text(label,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
        ),
      for (var i = 0; i < startOffset; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        Builder(
          builder: (_) {
            final dateStr = '$prefix-${d.toString().padLeft(2, '0')}';
            return _DayCell(
              day: d,
              date: dateStr,
              isToday: todayStr == dateStr,
              status: statusMap[dateStr] ?? DayStatus.noData,
              onTap: onDayTap,
              dots: categoryDots != null
                  ? (categoryDots![dateStr] ?? [])
                  : null,
            );
          },
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String date;
  final bool isToday;
  final DayStatus status;
  final void Function(String) onTap;
  final List<({Color color, bool cleared})>? dots;

  const _DayCell({
    required this.day,
    required this.date,
    required this.isToday,
    required this.status,
    required this.onTap,
    this.dots,
  });

  @override
  Widget build(BuildContext context) {
    Color? dotColor;
    if (dots == null) {
      if (status == DayStatus.clear) dotColor = const Color(0xFF10B981);
      if (status == DayStatus.notClear) dotColor = const Color(0xFFEF4444);
    }

    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isToday ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            if (dots != null && dots!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots!.take(5).map((d) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: d.cleared ? d.color : const Color(0xFF334155),
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
            ] else if (dotColor != null) ...[
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
