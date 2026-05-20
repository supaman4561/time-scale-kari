import React from 'react';
import { View, StyleSheet } from 'react-native';
import { COLORS, RADIUS } from '../theme';

interface Props {
  progress: number;
  color: string;
  overLimit?: boolean;
}

export default function ProgressBar({ progress, color, overLimit = false }: Props) {
  const clampedWidth = Math.min(Math.max(progress, 0), 1) * 100;
  return (
    <View style={styles.track}>
      <View
        style={[
          styles.fill,
          { width: `${clampedWidth}%`, backgroundColor: overLimit ? COLORS.dangerText : color },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  track: {
    height: 6,
    backgroundColor: COLORS.border,
    borderRadius: RADIUS.full,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    borderRadius: RADIUS.full,
  },
});
