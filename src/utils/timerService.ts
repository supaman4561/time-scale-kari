import VIForegroundService from '@supersami/rn-foreground-service';
import { formatDuration } from './dateUtils';

const TASK_NAME = 'timer-foreground';
const CHANNEL_ID = 'timer-channel';
const NOTIFICATION_ID = 1;

export async function startForegroundTimer(categoryName: string, startedAt: number): Promise<void> {
  await VIForegroundService.getInstance().createNotificationChannel({
    id: CHANNEL_ID,
    name: '計測中タイマー',
    description: 'タイマーの経過時間を表示します',
    enableVibration: false,
    importance: 2, // IMPORTANCE_LOW
  });

  await VIForegroundService.getInstance().startService({
    taskName: TASK_NAME,
    channelId: CHANNEL_ID,
    id: NOTIFICATION_ID,
    title: `⏱ ${categoryName} 計測中`,
    text: '0:00',
    icon: 'ic_notification',
    button: false,
  });

  // 毎秒通知の内容を更新
  const interval = setInterval(async () => {
    const elapsed = Math.floor(Date.now() / 1000) - startedAt;
    await VIForegroundService.getInstance().updateService({
      taskName: TASK_NAME,
      channelId: CHANNEL_ID,
      id: NOTIFICATION_ID,
      title: `⏱ ${categoryName} 計測中`,
      text: formatDuration(elapsed),
      icon: 'ic_notification',
      button: false,
    });
  }, 1000);

  // インターバルIDを保持して後でクリアできるようにする
  (globalThis as any).__timerServiceInterval = interval;
}

export async function stopForegroundTimer(): Promise<void> {
  const interval = (globalThis as any).__timerServiceInterval;
  if (interval != null) {
    clearInterval(interval);
    (globalThis as any).__timerServiceInterval = null;
  }
  await VIForegroundService.getInstance().stopService();
}
