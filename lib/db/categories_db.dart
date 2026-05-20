// lib/db/categories_db.dart
import '../models/category.dart';
import 'schema.dart';

Future<List<Category>> fetchCategories() async {
  final db = await getDb();
  final rows = await db.query('categories', orderBy: 'sort_order ASC');
  return rows.map(Category.fromMap).toList();
}

Future<int> insertCategory(Category category) async {
  final db = await getDb();
  return db.insert('categories', category.toMap());
}

Future<void> updateCategory(Category category) async {
  final db = await getDb();
  await db.update(
    'categories',
    category.toMap(),
    where: 'id = ?',
    whereArgs: [category.id],
  );
}

Future<void> deleteCategory(int id) async {
  final db = await getDb();
  await db.delete('categories', where: 'id = ?', whereArgs: [id]);
}

/// 並び替え後に全件のsort_orderを0,1,2...と振り直す
Future<void> reorderCategories(List<Category> ordered) async {
  final db = await getDb();
  final batch = db.batch();
  for (var i = 0; i < ordered.length; i++) {
    batch.update(
      'categories',
      {'sort_order': i},
      where: 'id = ?',
      whereArgs: [ordered[i].id],
    );
  }
  await batch.commit(noResult: true);
}
