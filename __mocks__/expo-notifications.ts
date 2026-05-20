export const requestPermissionsAsync = jest.fn(() =>
  Promise.resolve({ status: 'granted' })
);
export const scheduleNotificationAsync = jest.fn(() =>
  Promise.resolve('mock-notification-id')
);
export const cancelScheduledNotificationAsync = jest.fn(() =>
  Promise.resolve()
);
export const setNotificationHandler = jest.fn();
export const AndroidImportance = { MAX: 5, LOW: 2 };
export const setNotificationChannelAsync = jest.fn();
export const dismissNotificationAsync = jest.fn(() => Promise.resolve());
export const SchedulableTriggerInputTypes = { TIME_INTERVAL: 'timeInterval' };
