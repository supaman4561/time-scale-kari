import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/categories_db.dart';
import '../models/category.dart';

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() => fetchCategories();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(fetchCategories);
  }

  Future<void> add(Category category) async {
    final id = await insertCategory(category);
    final newCat = category.copyWith(id: id);
    state = AsyncData([...state.valueOrNull ?? [], newCat]);
  }

  Future<void> updateItem(Category category) async {
    await updateCategory(category);
    await reload();
  }

  Future<void> delete(int id) async {
    await deleteCategory(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((c) => c.id != id).toList(),
    );
  }

  Future<void> reorder(List<Category> ordered) async {
    await reorderCategories(ordered);
    state = AsyncData(ordered);
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(CategoryNotifier.new);
