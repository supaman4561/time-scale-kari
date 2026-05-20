import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, RADIUS, SPACING } from '../theme';
import { formatDuration } from '../utils/dateUtils';

interface Props {
  categoryName: string;
  startedAt: number;
  onStop: () => void;
}

export default function TimerBanner({ categoryName, startedAt, onStop }: Props) {
  const [elapsed, setElapsed] = useState(Math.floor(Date.now() / 1000) - startedAt);

  useEffect(() => {
    const interval = setInterval(() => {
      setElapsed(Math.floor(Date.now() / 1000) - startedAt);
    }, 1000);
    return () => clearInterval(interval);
  }, [startedAt]);

  return (
    <View style={styles.banner}>
      <View>
        <Text style={styles.label}>計測中</Text>
        <Text style={styles.name}>{categoryName}</Text>
      </View>
      <Text style={styles.timer}>{formatDuration(elapsed)}</Text>
      <TouchableOpacity style={styles.stopBtn} onPress={onStop}>
        <Text style={styles.stopText}>STOP</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: '#1e3a5f',
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.md,
  },
  label: { color: COLORS.accent, fontSize: 10, fontWeight: 'bold' },
  name: { color: COLORS.text, fontSize: 13 },
  timer: { color: COLORS.accent, fontSize: 22, fontWeight: 'bold', fontFamily: 'monospace' },
  stopBtn: {
    backgroundColor: COLORS.dangerText,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  stopText: { color: COLORS.white, fontSize: 12, fontWeight: 'bold' },
});
