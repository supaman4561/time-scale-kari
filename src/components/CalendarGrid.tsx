import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, RADIUS } from '../theme';

export type DayStatus = 'cleared' | 'failed' | 'holiday' | 'future' | 'today';

interface Props {
  year: number;
  month: number;
  statusMap: Record<string, DayStatus>;
  today: string;
  onDayPress: (date: string) => void;
}

const DAY_LABELS = ['日', '月', '火', '水', '木', '金', '土'];

const STATUS_STYLES: Record<DayStatus, { bg: string; text: string; bold?: boolean }> = {
  cleared: { bg: COLORS.success, text: COLORS.successText, bold: true },
  failed:  { bg: COLORS.danger,  text: COLORS.dangerText },
  holiday: { bg: COLORS.holiday, text: COLORS.holidayText },
  future:  { bg: 'transparent',  text: COLORS.textMuted },
  today:   { bg: 'transparent',  text: COLORS.accent, bold: true },
};

export default function CalendarGrid({ year, month, statusMap, today, onDayPress }: Props) {
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ];

  const getDateStr = (day: number) => {
    const m = String(month + 1).padStart(2, '0');
    const d = String(day).padStart(2, '0');
    return `${year}-${m}-${d}`;
  };

  const getStatus = (day: number): DayStatus => {
    const dateStr = getDateStr(day);
    if (dateStr === today) return 'today';
    if (dateStr > today) return 'future';
    return statusMap[dateStr] ?? 'future';
  };

  return (
    <View>
      <View style={styles.dayLabels}>
        {DAY_LABELS.map((l, i) => (
          <Text
            key={l}
            style={[
              styles.dayLabel,
              i === 0 && { color: COLORS.dangerText },
              i === 6 && { color: COLORS.accent },
            ]}
          >
            {l}
          </Text>
        ))}
      </View>
      <View style={styles.grid}>
        {cells.map((day, i) => {
          if (!day) return <View key={`empty-${i}`} style={styles.cell} />;
          const status = getStatus(day);
          const s = STATUS_STYLES[status];
          const isToday = status === 'today';
          const dateStr = getDateStr(day);
          const isPressable = dateStr <= today;
          return (
            <TouchableOpacity
              key={day}
              style={[styles.cell, { backgroundColor: s.bg }, isToday && styles.todayBorder]}
              onPress={() => isPressable && onDayPress(dateStr)}
              activeOpacity={isPressable ? 0.7 : 1}
            >
              <Text style={[styles.dayNum, { color: s.text }, s.bold && { fontWeight: 'bold' }]}>
                {day}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  dayLabels: { flexDirection: 'row', marginBottom: 4 },
  dayLabel: { flex: 1, textAlign: 'center', color: COLORS.textMuted, fontSize: 10 },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  cell: {
    width: `${100 / 7}%`,
    aspectRatio: 1,
    borderRadius: RADIUS.md,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 2,
  },
  todayBorder: { borderWidth: 2, borderColor: COLORS.accent },
  dayNum: { fontSize: 12 },
});
