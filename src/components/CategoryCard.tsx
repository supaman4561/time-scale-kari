import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Category } from '../db/categories';
import { isCategoryCleared } from '../utils/clearCheck';
import { formatDuration } from '../utils/dateUtils';
import ProgressBar from './ProgressBar';
import { COLORS, RADIUS, SPACING } from '../theme';

interface Props {
  category: Category;
  totalSec: number;
  budgetMin: number;
  isActive: boolean;
  onPress: () => void;
}

export default function CategoryCard({ category, totalSec, budgetMin, isActive, onPress }: Props) {
  const budgetSec = budgetMin * 60;
  const cleared = isCategoryCleared(category.type, budgetMin, totalSec);
  const progress = budgetSec > 0 ? totalSec / budgetSec : 0;
  const overLimit = category.type === 'limit' && totalSec > budgetSec + 300;

  const displayTime =
    category.type === 'quota'
      ? `${formatDuration(totalSec)} / ${formatDuration(budgetSec)}`
      : `残り ${formatDuration(Math.max(0, budgetSec - totalSec))}`;

  return (
    <TouchableOpacity
      style={[styles.card, isActive && styles.cardActive]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <View style={styles.header}>
        <View style={styles.left}>
          <View style={[styles.dot, { backgroundColor: category.color }]} />
          <Text style={styles.name}>{category.name}</Text>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{category.type === 'quota' ? 'ノルマ' : '上限'}</Text>
          </View>
          {cleared && <Text style={styles.check}>✓</Text>}
        </View>
        <Text style={[styles.time, overLimit && styles.timeOver]}>{displayTime}</Text>
      </View>
      <ProgressBar progress={progress} color={category.color} overLimit={overLimit} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  cardActive: {
    borderColor: COLORS.accent,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.sm,
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 10, height: 10, borderRadius: RADIUS.full },
  name: { color: COLORS.text, fontSize: 14, fontWeight: 'bold' },
  badge: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.sm,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
  badgeText: { color: COLORS.textMuted, fontSize: 10 },
  check: { color: COLORS.successText, fontSize: 14 },
  time: { color: COLORS.text, fontSize: 12, fontFamily: 'monospace' },
  timeOver: { color: COLORS.dangerText },
});
