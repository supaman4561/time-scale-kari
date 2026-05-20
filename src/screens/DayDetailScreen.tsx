import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, SafeAreaView } from 'react-native';
import { useRoute } from '@react-navigation/native';
import type { RouteProp } from '@react-navigation/native';
import { useCategoryStore } from '../store/categoryStore';
import { getSessionsForDate, getTotalSecByCategory, Session } from '../db/sessions';
import { isCategoryCleared, isDayCleared } from '../utils/clearCheck';
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

  const categoryResults = categories.map(c => ({
    category: c,
    budget: getBudgetForDate(c, dateObj),
    total: totals[c.id] ?? 0,
    catSessions: sessions.filter(s => s.category_id === c.id),
    cleared: isCategoryCleared(c.type, getBudgetForDate(c, dateObj), totals[c.id] ?? 0),
  }));
  const dayCleared = isDayCleared(categoryResults.map(r => r.cleared));

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.titleRow}>
          <Text style={styles.dateTitle}>{date}</Text>
          <View style={[styles.badge, { backgroundColor: dayCleared ? COLORS.success : COLORS.danger }]}>
            <Text style={[styles.badgeText, { color: dayCleared ? COLORS.successText : COLORS.dangerText }]}>
              {dayCleared ? '✓ クリア' : '✗ 未クリア'}
            </Text>
          </View>
        </View>

        {categoryResults.map(({ category, budget, total, catSessions, cleared }) => (
          <View key={category.id} style={styles.card}>
            <View style={styles.cardHeader}>
              <View style={styles.left}>
                <View style={[styles.dot, { backgroundColor: category.color }]} />
                <Text style={styles.catName}>{category.name}</Text>
                <Text style={styles.typeTag}>{category.type === 'quota' ? 'ノルマ' : '上限'}</Text>
              </View>
              <View style={styles.right}>
                <Text style={styles.totalTime}>
                  {formatDuration(total)} / {formatDuration(budget * 60)}
                </Text>
                {cleared && <Text style={styles.check}>✓</Text>}
              </View>
            </View>
            {catSessions.length > 0 && (
              <View style={styles.sessionList}>
                {catSessions.map(s => (
                  <View key={s.id} style={styles.sessionRow}>
                    <Text style={styles.sessionTime}>
                      {formatTime(s.started_at)}–{s.ended_at ? formatTime(s.ended_at) : '計測中'}
                    </Text>
                    <Text style={styles.sessionDuration}>
                      {formatDuration(s.duration_sec ?? 0)}
                    </Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        ))}

        {categories.length === 0 && (
          <Text style={styles.empty}>カテゴリがありません</Text>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { padding: SPACING.md },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.lg,
  },
  dateTitle: { color: COLORS.text, fontSize: 16, fontWeight: 'bold' },
  badge: { borderRadius: RADIUS.full, paddingHorizontal: SPACING.sm, paddingVertical: 2 },
  badgeText: { fontSize: 12, fontWeight: 'bold' },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  left: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  right: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  dot: { width: 8, height: 8, borderRadius: RADIUS.full },
  catName: { color: COLORS.text, fontSize: 13, fontWeight: 'bold' },
  typeTag: {
    color: COLORS.textMuted,
    fontSize: 10,
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: 4,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
  totalTime: { color: COLORS.text, fontSize: 12, fontFamily: 'monospace' },
  check: { color: COLORS.successText, fontSize: 14 },
  sessionList: {
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    marginTop: SPACING.sm,
    paddingTop: SPACING.sm,
    gap: 4,
  },
  sessionRow: { flexDirection: 'row', justifyContent: 'space-between' },
  sessionTime: { color: COLORS.textMuted, fontSize: 11 },
  sessionDuration: { color: COLORS.textMuted, fontSize: 11 },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40 },
});
