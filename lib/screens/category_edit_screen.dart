import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../theme.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final Category? category;
  const CategoryEditScreen({super.key, this.category});

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  late final TextEditingController _nameCtrl;
  late String _type;
  late String _color;
  late final TextEditingController _weekdayCtrl;
  late final TextEditingController _weekendCtrl;

  final _colors = [
    '#64B5F6', '#4DB6AC', '#81C784', '#FFB74D',
    '#F06292', '#BA68C8', '#FF8A65', '#90A4AE',
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _type = cat?.type ?? 'quota';
    _color = cat?.color.toUpperCase() ?? '#64B5F6';
    _weekdayCtrl = TextEditingController(
        text: cat?.weekdayBudgetMin.toString() ?? '60');
    _weekendCtrl = TextEditingController(
        text: cat?.weekendBudgetMin.toString() ?? '60');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weekdayCtrl.dispose();
    _weekendCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(categoryProvider.notifier);
    final cats = ref.read(categoryProvider).valueOrNull ?? [];

    if (widget.category == null) {
      await notifier.add(Category(
        name: name,
        type: _type,
        color: _color,
        weekdayBudgetMin: int.tryParse(_weekdayCtrl.text) ?? 60,
        weekendBudgetMin: int.tryParse(_weekendCtrl.text) ?? 60,
        sortOrder: cats.length,
      ));
    } else {
      await notifier.updateItem(widget.category!.copyWith(
        name: name,
        type: _type,
        color: _color,
        weekdayBudgetMin: int.tryParse(_weekdayCtrl.text) ?? 60,
        weekendBudgetMin: int.tryParse(_weekendCtrl.text) ?? 60,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('カテゴリを削除', style: TextStyle(color: AppColors.textMain)),
        content: const Text(
          'このカテゴリの全セッションも削除されます。よろしいですか？',
          style: TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(categoryProvider.notifier).delete(widget.category!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'カテゴリを編集' : 'カテゴリを追加',
            style: const TextStyle(fontSize: 15)),
        backgroundColor: AppColors.card,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('カテゴリ名'),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textMain),
              decoration: _inputDecoration('例: 読書'),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('タイプ'),
            Row(
              children: [
                _typeButton('quota', 'ノルマ（最低時間）'),
                const SizedBox(width: 8),
                _typeButton('limit', '上限（最大時間）'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _label('カラー'),
            Wrap(
              spacing: 8,
              children: _colors.map((c) {
                final color = Color(0xFF000000 |
                    int.parse(c.replaceFirst('#', ''), radix: 16));
                final selected = c.toUpperCase() == _color.toUpperCase();
                return GestureDetector(
                  onTap: () => setState(() => _color = c.toUpperCase()),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('平日の目標（分）'),
            TextField(
              controller: _weekdayCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain),
              decoration: _inputDecoration('60'),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('休日の目標（分）'),
            TextField(
              controller: _weekendCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textMain),
              decoration: _inputDecoration('60'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('保存',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(color: AppColors.textSub, fontSize: 12)),
      );

  Widget _typeButton(String value, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _type = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _type == value ? AppColors.blue : AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _type == value ? Colors.white : AppColors.textSub,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSub),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );
}
