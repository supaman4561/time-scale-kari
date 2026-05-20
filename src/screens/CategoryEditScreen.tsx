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
import type { CategoryType } from '../utils/clearCheck';

type Nav = NativeStackNavigationProp<SettingsStackParamList, 'CategoryEdit'>;
type Route = RouteProp<SettingsStackParamList, 'CategoryEdit'>;

const COLOR_OPTIONS = [
  '#ef5350', '#66bb6a', '#ab47bc', '#42a5f5',
  '#ffca28', '#ff7043', '#26c6da', '#ec407a',
];

function TimeInput({ label, minutes, onChange }: { label: string; minutes: number; onChange: (m: number) => void }) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.timeRow}>
        <TextInput
          style={styles.timeInput}
          keyboardType="number-pad"
          value={String(h)}
          onChangeText={v => onChange(Math.max(0, parseInt(v) || 0) * 60 + m)}
          maxLength={2}
        />
        <Text style={styles.timeSep}>時間</Text>
        <TextInput
          style={styles.timeInput}
          keyboardType="number-pad"
          value={String(m)}
          onChangeText={v => onChange(h * 60 + Math.min(59, parseInt(v) || 0))}
          maxLength={2}
        />
        <Text style={styles.timeSep}>分</Text>
      </View>
    </View>
  );
}

export default function CategoryEditScreen() {
  const navigation = useNavigation<Nav>();
  const { params } = useRoute<Route>();
  const categoryId = params?.categoryId;
  const { categories, addCategory, editCategory, removeCategory } = useCategoryStore();

  const existing = categoryId != null ? categories.find(c => c.id === categoryId) : undefined;

  const [name, setName] = useState(existing?.name ?? '');
  const [type, setType] = useState<CategoryType>(existing?.type ?? 'quota');
  const [color, setColor] = useState(existing?.color ?? COLOR_OPTIONS[0]);
  const [weekdayMin, setWeekdayMin] = useState(existing?.weekday_budget_min ?? 0);
  const [weekendMin, setWeekendMin] = useState(existing?.weekend_budget_min ?? 0);

  useLayoutEffect(() => {
    navigation.setOptions({ title: categoryId != null ? 'カテゴリ編集' : 'カテゴリ追加' });
  }, [navigation, categoryId]);

  const handleSave = () => {
    if (!name.trim()) { Alert.alert('エラー', 'カテゴリ名を入力してください'); return; }
    const data = { name: name.trim(), type, color, weekday_budget_min: weekdayMin, weekend_budget_min: weekendMin };
    if (existing) {
      editCategory(existing.id, data);
    } else {
      addCategory(data);
    }
    navigation.goBack();
  };

  const handleDelete = () => {
    if (!existing) return;
    Alert.alert('削除', `「${existing.name}」を削除しますか？`, [
      { text: 'キャンセル', style: 'cancel' },
      { text: '削除', style: 'destructive', onPress: () => { removeCategory(existing.id); navigation.goBack(); } },
    ]);
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        <View style={styles.field}>
          <Text style={styles.label}>カテゴリ名</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="例: 仕事"
            placeholderTextColor={COLORS.textMuted}
          />
        </View>

        <View style={styles.field}>
          <Text style={styles.label}>タイプ</Text>
          <View style={styles.typeRow}>
            {(['quota', 'limit'] as CategoryType[]).map(t => (
              <TouchableOpacity
                key={t}
                style={[styles.typeBtn, type === t && styles.typeBtnActive]}
                onPress={() => setType(t)}
              >
                <Text style={[styles.typeBtnText, type === t && styles.typeBtnTextActive]}>
                  {t === 'quota' ? 'ノルマ' : '上限'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.field}>
          <Text style={styles.label}>カラー</Text>
          <View style={styles.colorRow}>
            {COLOR_OPTIONS.map(c => (
              <TouchableOpacity
                key={c}
                style={[styles.colorDot, { backgroundColor: c }, color === c && styles.colorDotActive]}
                onPress={() => setColor(c)}
              />
            ))}
          </View>
        </View>

        <TimeInput label="平日の目標時間" minutes={weekdayMin} onChange={setWeekdayMin} />
        <TimeInput label="休日の目標時間" minutes={weekendMin} onChange={setWeekendMin} />

        {existing && (
          <TouchableOpacity style={styles.deleteBtn} onPress={handleDelete}>
            <Text style={styles.deleteBtnText}>このカテゴリを削除</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
          <Text style={styles.saveBtnText}>保存</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { padding: SPACING.md },
  field: { marginBottom: SPACING.lg },
  label: {
    color: COLORS.textMuted,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: SPACING.sm,
  },
  input: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    color: COLORS.text,
    fontSize: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  typeRow: { flexDirection: 'row', gap: SPACING.sm },
  typeBtn: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  typeBtnActive: { borderColor: COLORS.accent },
  typeBtnText: { color: COLORS.textMuted, fontSize: 14, fontWeight: 'bold' },
  typeBtnTextActive: { color: COLORS.accent },
  colorRow: { flexDirection: 'row', gap: SPACING.sm, flexWrap: 'wrap' },
  colorDot: { width: 32, height: 32, borderRadius: RADIUS.full },
  colorDotActive: { borderWidth: 3, borderColor: COLORS.white },
  timeRow: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm },
  timeInput: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    padding: SPACING.sm,
    color: COLORS.text,
    fontSize: 16,
    width: 52,
    textAlign: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  timeSep: { color: COLORS.textMuted, fontSize: 13 },
  deleteBtn: { alignItems: 'center', padding: SPACING.md, marginBottom: SPACING.sm },
  deleteBtnText: { color: COLORS.dangerText, fontSize: 14 },
  saveBtn: {
    backgroundColor: COLORS.accent,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    alignItems: 'center',
    marginBottom: SPACING.xl,
  },
  saveBtnText: { color: COLORS.white, fontSize: 15, fontWeight: 'bold' },
});
