import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, StyleSheet, SafeAreaView } from 'react-native';
import { useRoute } from '@react-navigation/native';
import type { RouteProp } from '@react-navigation/native';
import { useCategoryStore } from '../store/categoryStore';
import { getSessionsForDate, getTotalSecByCategory, Session } from '../db/sessions';
import { isCategoryCleared } from '../utils/clearCheck';
import { getBudgetForDate, formatDuration, formatTime } from '../utils/dateUtils';
import { COLORS, SPACING, RADIUS } from '../theme';
import type { CalendarStackParamList } from '../navigation/AppNavigator';

type Route = RouteProp<CalendarStackParamList, 'DayDetail'>;

export default function DayDetailScreen() {
  const { params: { date } } = useRoute<Route>();
  const categories = useCategoryStore(s => s.categories);
  const [totals, setTotals] = useState<Record<number, number>>({});
  const [sessions, setSessions] = useState<Session[]>([]);
  const dateObj = new Date(`${date}T00:00:00`);

  useEffect(() => {
    setTotals(getTotalSecByCategory(date));
    setSessions(getSessionsForDate(date));
  }, [date]);

  return (
    <SafeAreaView style={styles.safe}>
      <FlatList
        data={categories}
        keyExtractor={item => String(item.id)}
        contentContainerStyle={styles.container}
        ListHeaderComponent={<Text style={styles.dateTitle}>{date}</Text>}
        renderItem={({ item: category }) => {
          const budget = getBudgetForDate(category, dateObj);
          const total = totals[category.id] ?? 0;
          const cleared = isCategoryCleared(category.type, budget, total);
          const catSessions = sessions.filter(s => s.category_id === category.id);
          return (
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <View style={styles.left}>
                  <View style={[styles.dot, { backgroundColor: category.color }]} />
                  <Text style={styles.catName}>{category.name}</Text>
                  {cleared && <Text style={styles.check}>✓</Text>}
                </View>
                <Text style={styles.totalTime}>{formatDuration(total)}</Text>
              </View>
              {catSessions.map(s => (
                <Text key={s.id} style={styles.session}>
                  {formatTime(s.started_at)} – {s.ended_at ? formatTime(s.ended_at) : '計測中'}
                  {'  '}
                  {s.duration_sec != null ? formatDuration(s.duration_sec) : ''}
                </Text>
              ))}
              {catSessions.length === 0 && (
                <Text style={styles.noSession}>記録なし</Text>
              )}
            </View>
          );
        }}
        ListEmptyComponent={<Text style={styles.empty}>カテゴリがありません</Text>}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { padding: SPACING.md },
  dateTitle: { color: COLORS.textMuted, fontSize: 13, textAlign: 'center', marginBottom: SPACING.md },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 },
  left: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 10, height: 10, borderRadius: RADIUS.full },
  catName: { color: COLORS.text, fontSize: 14, fontWeight: 'bold' },
  check: { color: COLORS.successText, fontSize: 14 },
  totalTime: { color: COLORS.accent, fontSize: 13, fontFamily: 'monospace' },
  session: { color: COLORS.textMuted, fontSize: 12, marginTop: 4 },
  noSession: { color: COLORS.textMuted, fontSize: 12, marginTop: 4, fontStyle: 'italic' },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40 },
});
