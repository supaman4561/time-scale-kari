import React, { useState, useCallback } from 'react';
import { View, FlatList, Text, StyleSheet, SafeAreaView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useCategoryStore } from '../store/categoryStore';
import { useTimerStore } from '../store/timerStore';
import { getTotalSecByCategory } from '../db/sessions';
import { getBudgetForDate, getLocalDateString } from '../utils/dateUtils';
import { scheduleTimerNotification, cancelNotification } from '../utils/notifications';
import { COLORS, SPACING } from '../theme';
import CategoryCard from '../components/CategoryCard';
import TimerBanner from '../components/TimerBanner';
import { Category } from '../db/categories';

export default function TodayScreen() {
  const categories = useCategoryStore(s => s.categories);
  const { activeSessionId, activeCategoryId, startedAt, notificationId, startTimer, stopTimer, setNotificationId } = useTimerStore();
  const [totalByCategory, setTotalByCategory] = useState<Record<number, number>>({});
  const today = getLocalDateString();
  const now = new Date();

  const refresh = useCallback(() => {
    setTotalByCategory(getTotalSecByCategory(today));
  }, [today]);

  useFocusEffect(useCallback(() => {
    refresh();
    const interval = setInterval(refresh, 5000);
    return () => clearInterval(interval);
  }, [refresh]));

  const handlePress = async (category: Category) => {
    if (activeCategoryId === category.id) {
      if (notificationId) await cancelNotification(notificationId);
      stopTimer();
    } else if (activeSessionId === null) {
      startTimer(category.id, category.name, getBudgetForDate(category, now) * 60);
      const budgetSec = getBudgetForDate(category, now) * 60;
      if (budgetSec > 0) {
        const nid = await scheduleTimerNotification(
          `${category.name}の時間になりました`,
          `設定時間 ${Math.floor(budgetSec / 60)} 分に達しました`,
          budgetSec,
        );
        setNotificationId(nid);
      }
    }
    setTimeout(refresh, 200);
  };

  const handleStop = async () => {
    if (notificationId) await cancelNotification(notificationId);
    stopTimer();
    setTimeout(refresh, 200);
  };

  const activeCategory = categories.find(c => c.id === activeCategoryId);

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Text style={styles.dateText}>
          {today}（{['日', '月', '火', '水', '木', '金', '土'][now.getDay()]}）
        </Text>

        {activeCategory && startedAt && (
          <TimerBanner
            categoryName={activeCategory.name}
            startedAt={startedAt}
            onStop={handleStop}
          />
        )}

        <FlatList
          data={categories}
          keyExtractor={item => String(item.id)}
          renderItem={({ item }) => (
            <CategoryCard
              category={item}
              totalSec={totalByCategory[item.id] ?? 0}
              budgetMin={getBudgetForDate(item, now)}
              isActive={item.id === activeCategoryId}
              onPress={() => handlePress(item)}
            />
          )}
          ListEmptyComponent={
            <Text style={styles.empty}>設定画面からカテゴリを追加してください</Text>
          }
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  dateText: { color: COLORS.textMuted, fontSize: 13, textAlign: 'center', marginBottom: SPACING.md },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40 },
});
