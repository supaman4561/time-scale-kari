// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(const InitializationSettings(android: android));
}

Future<void> showBudgetNotification({
  required String categoryName,
  required bool isQuota,
}) async {
  final body = isQuota ? '予定時間に達しました' : '上限時間を超えました';
  await _plugin.show(
    1,
    categoryName,
    body,
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
