import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export async function requestNotificationPermission(): Promise<boolean> {
  if (!Device.isDevice) return false;
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('timer', {
      name: 'タイマー通知',
      importance: Notifications.AndroidImportance.MAX,
    });
  }
  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

export async function scheduleTimerNotification(
  title: string,
  body: string,
  delaySeconds: number
): Promise<string> {
  return Notifications.scheduleNotificationAsync({
    content: { title, body, sound: true },
    trigger: { type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL, seconds: delaySeconds, repeats: false },
  });
}

export async function cancelNotification(notificationId: string): Promise<void> {
  await Notifications.cancelScheduledNotificationAsync(notificationId);
}

const ONGOING_ID = 'timer-ongoing';

export async function showOngoingTimerNotification(categoryName: string): Promise<void> {
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('timer-ongoing', {
      name: '計測中',
      importance: Notifications.AndroidImportance.LOW,
      sound: null,
      vibrationPattern: [],
      enableVibrate: false,
      showBadge: false,
    });
  }
  await Notifications.scheduleNotificationAsync({
    identifier: ONGOING_ID,
    content: {
      title: `⏱ ${categoryName} 計測中`,
      body: 'タップしてアプリに戻る',
      sound: false,
      sticky: true,
      autoDismiss: false,
    },
    trigger: null,
  });
}

export async function dismissOngoingTimerNotification(): Promise<void> {
  try {
    await Notifications.dismissNotificationAsync(ONGOING_ID);
  } catch {
    // already dismissed
  }
}
