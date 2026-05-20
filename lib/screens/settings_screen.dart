import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../theme.dart';
import 'category_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Color _parseColor(String hex) {
    try {
      return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('カテゴリ',
                    style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CategoryEditScreen()),
                    );
                    ref.read(categoryProvider.notifier).reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (categories) => Expanded(
                child: ReorderableListView.builder(
                  itemCount: categories.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final reordered = [...categories];
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    ref.read(categoryProvider.notifier).reorder(reordered);
                  },
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final dotColor = _parseColor(cat.color);
                    return ListTile(
                      key: ValueKey(cat.id),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: dotColor.withAlpha(160), blurRadius: 6)
                          ],
                        ),
                      ),
                      title: Text(cat.name,
                          style: const TextStyle(color: AppColors.textMain)),
                      subtitle: Text(
                        cat.type == 'quota' ? 'ノルマ' : '上限',
                        style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.drag_handle, color: AppColors.textSub),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CategoryEditScreen(category: cat)),
                        );
                        ref.read(categoryProvider.notifier).reload();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
