import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import AppNavigator from './src/navigation/AppNavigator';
import { initDb } from './src/db/schema';
import { useCategoryStore } from './src/store/categoryStore';
import { useTimerStore } from './src/store/timerStore';
import { requestNotificationPermission } from './src/utils/notifications';

export default function App() {
  useEffect(() => {
    initDb();
    useCategoryStore.getState().loadCategories();
    useTimerStore.getState().restoreTimer();
    requestNotificationPermission();
  }, []);

  return (
    <>
      <StatusBar style="light" />
      <AppNavigator />
    </>
  );
}
