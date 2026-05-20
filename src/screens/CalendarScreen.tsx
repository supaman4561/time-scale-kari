import React, { useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useFocusEffect } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useCategoryStore } from '../store/categoryStore';
import { getMonthTotals } from '../db/sessions';
import { isCategoryCleared, isDayCleared } from '../utils/clearCheck';
import { getBudgetForDate, getLocalDateString } from '../utils/dateUtils';
import CalendarGrid, { DayStatus } from '../components/CalendarGrid';
import { COLORS, SPACING } from '../theme';
import type { CalendarStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<CalendarStackParamList, 'CalendarHome'>;

export default function CalendarScreen() {
  const navigation = useNavigation<Nav>();
  const categories = useCategoryStore(s => s.categories);
  const today = getLocalDateString();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth());
  const [statusMap, setStatusMap] = useState<Record<string, DayStatus>>({});

  const buildStatusMap = useCallback(() => {
    const totals = getMonthTotals(year, month);
    const map: Record<string, DayStatus> = {};
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    for (let d = 1; d <= daysInMonth; d++) {
      const m = String(month + 1).padStart(2, '0');
      const dd = String(d).padStart(2, '0');
      const dateStr = `${year}-${m}-${dd}`;
      if (dateStr >= today) continue;
      const dayTotals = totals[dateStr] ?? {};
      const date = new Date(year, month, d);
      const results = categories.map(c => {
        const budget = getBudgetForDate(c, date);
        const total = dayTotals[c.id] ?? 0;
        return isCategoryCleared(c.type, budget, total);
      });
      map[dateStr] = isDayCleared(results) ? 'cleared' : 'failed';
    }
    setStatusMap(map);
  }, [year, month, today, categories]);

  useFocusEffect(useCallback(() => {
    buildStatusMap();
  }, [buildStatusMap]));

  const prevMonth = () => {
    if (month === 0) { setYear(y => y - 1); setMonth(11); }
    else setMonth(m => m - 1);
  };
  const nextMonth = () => {
    if (month === 11) { setYear(y => y + 1); setMonth(0); }
    else setMonth(m => m + 1);
  };

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={prevMonth} style={styles.arrow}>
            <Text style={styles.arrowText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{year}年{month + 1}月</Text>
          <TouchableOpacity onPress={nextMonth} style={styles.arrow}>
            <Text style={styles.arrowText}>›</Text>
          </TouchableOpacity>
        </View>
        <CalendarGrid
          year={year}
          month={month}
          statusMap={statusMap}
          today={today}
          onDayPress={date => navigation.navigate('DayDetail', { date })}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.md,
  },
  title: { color: COLORS.text, fontSize: 16, fontWeight: 'bold' },
  arrow: { padding: SPACING.sm },
  arrowText: { color: COLORS.accent, fontSize: 28, lineHeight: 32 },
});
