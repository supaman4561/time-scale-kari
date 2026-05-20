import ReactNativeForegroundService from '@supersami/rn-foreground-service';
import { formatDuration } from './dateUtils';

const NOTIFICATION_ID = 100;

// Must be called at module level before startService
ReactNativeForegroundService.register({
  config: {
    alert: false,
    onServiceErrorCallBack: () => {},
  },
});

let activeTaskId: string | null = null;

export async function startForegroundTimer(categoryName: string, startedAt: number): Promise<void> {
  // ServiceType is required by Android 14+ but missing from the TS types
  await (ReactNativeForegroundService.start as any)({
    id: NOTIFICATION_ID,
    title: `⏱ ${categoryName} 計測中`,
    message: '0:00',
    ServiceType: 'specialUse',
    icon: 'ic_launcher',
    importance: 'low',
    visibility: 'public',
  });

  activeTaskId = ReactNativeForegroundService.add_task(
    async () => {
      const elapsed = Math.floor(Date.now() / 1000) - startedAt;
      await (ReactNativeForegroundService.update as any)({
        id: NOTIFICATION_ID,
        title: `⏱ ${categoryName} 計測中`,
        message: formatDuration(elapsed),
        ServiceType: 'specialUse',
        icon: 'ic_launcher',
        importance: 'low',
        visibility: 'public',
      });
    },
    { delay: 1000, onLoop: true },
  );
}

export async function stopForegroundTimer(): Promise<void> {
  if (activeTaskId) {
    ReactNativeForegroundService.remove_task(activeTaskId);
    activeTaskId = null;
  }
  await ReactNativeForegroundService.stop();
}
