import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _health = Health();
const _prefKey = 'health_connect_enabled';

/// 連携状態を返す（SharedPrefsで保存したフラグ + 実際の権限を確認）
Future<bool> isHealthConnected() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(_prefKey) ?? false;
  if (!enabled) return false;
  try {
    final hasPerm = await _health.hasPermissions([HealthDataType.SLEEP_SESSION]);
    return hasPerm == true;
  } catch (_) {
    return false;
  }
}

/// 連携する（権限リクエスト → SharedPrefsに保存）
Future<bool> connectHealthConnect() async {
  try {
    await _health.configure();
    final granted = await _health.requestAuthorization([HealthDataType.SLEEP_SESSION]);
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    }
    return granted;
  } catch (_) {
    return false;
  }
}

/// 連携を解除する（SharedPrefsのフラグをfalseに。権限自体はHC側で管理）
Future<void> disconnectHealthConnect() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey, false);
}

/// 指定日の睡眠セッションを取得（連携済みのときのみ呼ぶこと）
Future<List<({DateTime start, DateTime end})>> getSleepForDate(String date) async {
  try {
    final dt = DateTime.parse(date);
    final windowStart = DateTime(dt.year, dt.month, dt.day - 1, 12);
    final windowEnd = DateTime(dt.year, dt.month, dt.day + 1);
    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.SLEEP_SESSION],
      startTime: windowStart,
      endTime: windowEnd,
    );
    return data.map((d) => (start: d.dateFrom, end: d.dateTo)).toList();
  } catch (_) {
    return [];
  }
}
