import React from 'react';
import { View, Text, FlatList, TouchableOpacity, Alert, StyleSheet, SafeAreaView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useCategoryStore } from '../store/categoryStore';
import { COLORS, SPACING, RADIUS } from '../theme';
import type { SettingsStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<SettingsStackParamList, 'SettingsHome'>;

export default function SettingsScreen() {
  const navigation = useNavigation<Nav>();
  const { categories, removeCategory } = useCategoryStore();

  const confirmDelete = (id: number, name: string) => {
    Alert.alert('削除確認', `「${name}」を削除しますか？`, [
      { text: 'キャンセル', style: 'cancel' },
      { text: '削除', style: 'destructive', onPress: () => removeCategory(id) },
    ]);
  };

  return (
    <SafeAreaView style={styles.safe}>
      <FlatList
        data={categories}
        keyExtractor={item => String(item.id)}
        contentContainerStyle={styles.container}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.left}>
              <View style={[styles.dot, { backgroundColor: item.color }]} />
              <View style={styles.info}>
                <Text style={styles.name}>{item.name}</Text>
                <Text style={styles.sub}>
                  {item.type === 'quota' ? 'ノルマ' : '上限'} / 平日 {item.weekday_budget_min}分 / 週末 {item.weekend_budget_min}分
                </Text>
              </View>
            </View>
            <View style={styles.actions}>
              <TouchableOpacity
                style={styles.editBtn}
                onPress={() => navigation.navigate('CategoryEdit', { categoryId: item.id })}
              >
                <Text style={styles.editText}>編集</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.deleteBtn}
                onPress={() => confirmDelete(item.id, item.name)}
              >
                <Text style={styles.deleteText}>削除</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={<Text style={styles.empty}>カテゴリがありません</Text>}
        ListFooterComponent={
          <TouchableOpacity
            style={styles.addBtn}
            onPress={() => navigation.navigate('CategoryEdit', {})}
          >
            <Text style={styles.addText}>＋ カテゴリを追加</Text>
          </TouchableOpacity>
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { padding: SPACING.md },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: 10, flex: 1 },
  dot: { width: 12, height: 12, borderRadius: RADIUS.full, flexShrink: 0 },
  info: { flex: 1 },
  name: { color: COLORS.text, fontSize: 14, fontWeight: 'bold' },
  sub: { color: COLORS.textMuted, fontSize: 11, marginTop: 2 },
  actions: { flexDirection: 'row', gap: 8, marginLeft: SPACING.sm },
  editBtn: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
  },
  editText: { color: COLORS.accent, fontSize: 12 },
  deleteBtn: {
    backgroundColor: COLORS.danger,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
  },
  deleteText: { color: COLORS.dangerText, fontSize: 12 },
  addBtn: {
    backgroundColor: COLORS.accent,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    alignItems: 'center',
    marginTop: SPACING.sm,
  },
  addText: { color: COLORS.bg, fontSize: 15, fontWeight: 'bold' },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40, marginBottom: SPACING.lg },
});
