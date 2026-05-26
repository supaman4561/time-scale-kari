import 'package:health/health.dart';

final _health = Health();

Future<bool> requestSleepPermission() async {
  try {
    await _health.configure();
    return await _health.requestAuthorization([HealthDataType.SLEEP_SESSION]);
  } catch (_) {
    return false;
  }
}

Future<List<({DateTime start, DateTime end})>> getSleepForDate(
    String date) async {
  try {
    final dt = DateTime.parse(date);
    // noon-to-noon ウィンドウ: 前日正午から当日正午（夜をまたぐ睡眠を取得）
    final windowStart = DateTime(dt.year, dt.month, dt.day - 1, 12);
    final windowEnd = DateTime(dt.year, dt.month, dt.day, 12);

    final data = await _health.getHealthDataFromTypes(
      types: [HealthDataType.SLEEP_SESSION],
      startTime: windowStart,
      endTime: windowEnd,
    );
    return data
        .map((d) => (start: d.dateFrom, end: d.dateTo))
        .toList();
  } catch (_) {
    return [];
  }
}
