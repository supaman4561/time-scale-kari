import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import 'progress_bar.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final int totalSec;
  final bool isActive;
  final bool isAnyActive;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.totalSec,
    required this.isActive,
    required this.isAnyActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgetMin = getBudgetForDate(
      category.weekdayBudgetMin,
      category.weekendBudgetMin,
      now,
    );
    final budgetSec = budgetMin * 60;
    final cleared = isCategoryCleared(
      type: category.type,
      budgetMin: budgetMin,
      totalSec: totalSec,
    );
    final isOver = category.type == 'limit' && totalSec > budgetSec + 300;
    final dotColor = _parseColor(category.color);
    final progress = budgetSec > 0 ? totalSec / budgetSec : 0.0;

    final isDisabled = isAnyActive && !isActive;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: cleared
                ? Border.all(color: const Color(0xFF10B981).withAlpha(76), width: 1)
                : isOver
                    ? Border.all(color: const Color(0xFFEF4444).withAlpha(100), width: 1)
                    : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: dotColor.withAlpha(160), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (cleared && !isOver) _badge('CLEAR', const Color(0xFF10B981)),
                  if (isOver) _badge('超過', const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatSecAsMin(totalSec)} / $budgetMin分',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProgressBar(progress: progress, color: dotColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );

  String _formatSecAsMin(int sec) {
    final m = sec ~/ 60;
    return '$m分';
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(0xFF000000 | value);
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }
}
