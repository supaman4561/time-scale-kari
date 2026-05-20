// lib/utils/clear_check.dart

/// カテゴリのクリア判定
/// quota: totalSec >= budgetMin * 60
/// limit: totalSec <= budgetMin * 60 + 300（5分猶予）
bool isCategoryCleared({
  required String type,
  required int budgetMin,
  required int totalSec,
}) {
  final budgetSec = budgetMin * 60;
  if (type == 'quota') return totalSec >= budgetSec;
  return totalSec <= budgetSec + 300;
}

/// 1日クリア判定（全カテゴリクリア、かつ1件以上）
bool isDayCleared(List<bool> results) {
  return results.isNotEmpty && results.every((r) => r);
}
