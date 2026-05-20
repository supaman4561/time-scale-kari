import React, { useState, useLayoutEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  ScrollView, StyleSheet, SafeAreaView, Alert,
} from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import type { RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useCategoryStore } from '../store/categoryStore';
import { COLORS, SPACING, RADIUS } from '../theme';
import type { SettingsStackParamList } from '../navigation/AppNavigator';

type Nav = NativeStackNavigationProp<SettingsStackParamList, 'CategoryEdit'>;
type Route = RouteProp<SettingsStackParamList, 'CategoryEdit'>;

const COLOR_OPTIONS = [
  '#64b5f6', '#ef5350', '#66bb6a', '#ffa726', '#ab47bc',
  '#26c6da', '#ff7043', '#42a5f5', '#ec407a', '#9ccc65',
];

export default function CategoryEditScreen() {
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<Route>();
  const categoryId = params?.categoryId;
  const { categories, addCategory, editCategory } = useCategoryStore();

  const existing = categoryId != null ? categories.find(c => c.id === categoryId) : undefined;

  const [name, setName] = useState(existing?.name ?? '');
  const [type, setType] = useState<'quota' | 'limit'>(existing?.type ?? 'quota');
  const [color, setColor] = useState(existing?.color ?? COLOR_OPTIONS[0]);
  const [weekdayMin, setWeekdayMin] = useState(String(existing?.weekday_budget_min ?? 60));
  const [weekendMin, setWeekendMin] = useState(String(existing?.weekend_budget_min ?? 60));

  useLayoutEffect(() => {
    navigation.setOptions({ title: categoryId != null ? 'カテゴリ編集' : 'カテゴリ追加' });
  }, [navigation, categoryId]);

  const handleSave = () => {
    const trimmed = name.trim();
    if (!trimmed) { Alert.alert('エラー', '名前を入力してください'); return; }
    const weekday = parseInt(weekdayMin, 10);
    const weekend = parseInt(weekendMin, 10);
    if (isNaN(weekday) || weekday < 0) { Alert.alert('エラー', '平日の時間を正しく入力してください'); return; }
    if (isNaN(weekend) || weekend < 0) { Alert.alert('エラー', '週末の時間を正しく入力してください'); return; }

    const data = { name: trimmed, type, color, weekday_budget_min: weekday, weekend_budget_min: weekend };
    if (categoryId != null) {
      editCategory(categoryId, data);
    } else {
      addCategory(data);
    }
    navigation.goBack();
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <Text style={styles.label}>名前</Text>
        <TextInput
          style={styles.input}
          value={name}
          onChangeText={setName}
          placeholder="カテゴリ名"
          placeholderTextColor={COLORS.textMuted}
        />

        <Text style={styles.label}>タイプ</Text>
        <View style={styles.toggle}>
          <TouchableOpacity
            style={[styles.toggleBtn, type === 'quota' && styles.toggleActive]}
            onPress={() => setType('quota')}
          >
            <Text style={[styles.toggleText, type === 'quota' && styles.toggleActiveText]}>ノルマ</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.toggleBtn, type === 'limit' && styles.toggleActive]}
            onPress={() => setType('limit')}
          >
            <Text style={[styles.toggleText, type === 'limit' && styles.toggleActiveText]}>上限</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>カラー</Text>
        <View style={styles.colorRow}>
          {COLOR_OPTIONS.map(c => (
            <TouchableOpacity
              key={c}
              style={[styles.colorSwatch, { backgroundColor: c }, color === c && styles.colorSelected]}
              onPress={() => setColor(c)}
            />
          ))}
        </View>

        <Text style={styles.label}>平日の時間（分）</Text>
        <TextInput
          style={styles.input}
          value={weekdayMin}
          onChangeText={setWeekdayMin}
          keyboardType="numeric"
          placeholder="60"
          placeholderTextColor={COLORS.textMuted}
        />

        <Text style={styles.label}>週末の時間（分）</Text>
        <TextInput
          style={styles.input}
          value={weekendMin}
          onChangeText={setWeekendMin}
          keyboardType="numeric"
          placeholder="60"
          placeholderTextColor={COLORS.textMuted}
        />

        <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
          <Text style={styles.saveText}>保存</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { padding: SPACING.lg },
  label: { color: COLORS.textMuted, fontSize: 12, marginBottom: SPACING.xs, marginTop: SPACING.md },
  input: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    color: COLORS.text,
    fontSize: 15,
  },
  toggle: { flexDirection: 'row', gap: SPACING.sm },
  toggleBtn: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    padding: SPACING.md,
    alignItems: 'center',
  },
  toggleActive: { backgroundColor: COLORS.accent },
  toggleText: { color: COLORS.textMuted, fontSize: 14, fontWeight: 'bold' },
  toggleActiveText: { color: COLORS.bg },
  colorRow: { flexDirection: 'row', flexWrap: 'wrap', gap: SPACING.sm },
  colorSwatch: { width: 32, height: 32, borderRadius: RADIUS.full },
  colorSelected: { borderWidth: 3, borderColor: COLORS.white },
  saveBtn: {
    backgroundColor: COLORS.accent,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    alignItems: 'center',
    marginTop: SPACING.xl,
  },
  saveText: { color: COLORS.bg, fontSize: 16, fontWeight: 'bold' },
});
