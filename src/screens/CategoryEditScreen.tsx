import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS } from '../theme';

export default function CategoryEditScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>カテゴリ編集</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg, alignItems: 'center', justifyContent: 'center' },
  text: { color: COLORS.text, fontSize: 18 },
});
