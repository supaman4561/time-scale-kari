// lib/utils/date_utils.dart

/// ローカル日付を YYYY-MM-DD 形式で返す
String getLocalDateString([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// 土・日を休日と判定
bool isWeekend([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
}

/// 指定日の予算分数を返す（平日 or 休日）
int getBudgetForDate(int weekdayBudgetMin, int weekendBudgetMin, [DateTime? dt]) {
  return isWeekend(dt) ? weekendBudgetMin : weekdayBudgetMin;
}

/// 経過秒数を HH:MM:SS 形式にフォーマット
String formatDuration(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// 曜日の日本語表記
const _weekdayJa = ['月', '火', '水', '木', '金', '土', '日'];
String weekdayJa([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return _weekdayJa[d.weekday - 1];
}
