// lib/services/foreground_task_handler.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/date_utils.dart';

/// vm:entry-point が必須（別Isolateで実行される）
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  int? _startedAt;
  int? _budgetSec;
  String _categoryName = '';
  bool _budgetNotified = false;
  final _notifPlugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notifPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      _startedAt = data['started_at'] as int?;
      _budgetSec = data['budget_sec'] as int?;
      _categoryName = data['category_name'] as String? ?? '';
      _budgetNotified = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_startedAt == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now - _startedAt!;

    FlutterForegroundTask.updateService(
      notificationTitle: '$_categoryName 計測中',
      notificationText: formatDuration(elapsed),
    );

    // 予算到達通知（1回だけ）
    if (!_budgetNotified && _budgetSec != null && elapsed >= _budgetSec!) {
      _budgetNotified = true;
      _notifPlugin.show(
        1,
        _categoryName,
        '予定時間に達しました',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_channel',
            '予算通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// フォアグラウンドサービスの初期化（main()で一度だけ呼ぶ）
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'timer_channel',
      channelName: 'タイマー',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
}

Future<void> startForegroundTimer({
  required String categoryName,
  required int startedAt,
  required int budgetSec,
}) async {
  await FlutterForegroundTask.startService(
    serviceId: 100,
    notificationTitle: '$categoryName 計測中',
    notificationText: '0:00',
    callback: startCallback,
  );
  // データを TaskHandler へ送信
  FlutterForegroundTask.sendDataToTask({
    'started_at': startedAt,
    'budget_sec': budgetSec,
    'category_name': categoryName,
  });
}

Future<void> stopForegroundTimer() async {
  await FlutterForegroundTask.stopService();
}
