// lib/db/sessions_db.dart
import '../models/session.dart';
import 'schema.dart';

/// セッション開始（ended_at = null）
Future<int> startSession(int categoryId, String date) async {
  final db = await getDb();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return db.insert('sessions', {
    'category_id': categoryId,
    'date': date,
    'started_at': now,
  });
}

/// セッション終了
Future<void> stopSession(int sessionId) async {
  final db = await getDb();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
  if (rows.isEmpty) return;
  final startedAt = rows.first['started_at'] as int;
  await db.update(
    'sessions',
    {'ended_at': now, 'duration_sec': now - startedAt},
    where: 'id = ?',
    whereArgs: [sessionId],
  );
}

/// 計測中セッションを1件取得
Future<Session?> getInProgressSession() async {
  final db = await getDb();
  final rows = await db.query(
    'sessions',
    where: 'ended_at IS NULL',
    orderBy: 'started_at DESC',
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return Session.fromMap(rows.first);
}

/// 計測中セッションを異常終了として閉じる
Future<void> closeAbandonedSessions() async {
  final db = await getDb();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final rows = await db.query('sessions', where: 'ended_at IS NULL', orderBy: 'started_at ASC');
  if (rows.isEmpty) return;
  final toClose = rows.length > 1 ? rows.sublist(0, rows.length - 1) : <Map<String, dynamic>>[];
  final batch = db.batch();
  for (final row in toClose) {
    final startedAt = row['started_at'] as int;
    batch.update(
      'sessions',
      {'ended_at': now, 'duration_sec': now - startedAt},
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
  await batch.commit(noResult: true);
}

/// 指定日のカテゴリ別合計秒数
Future<Map<int, int>> getTotalSecByCategory(String date) async {
  final db = await getDb();
  final rows = await db.rawQuery('''
    SELECT category_id,
           SUM(COALESCE(duration_sec, CAST((strftime('%s','now') - started_at) AS INTEGER))) AS total
    FROM sessions
    WHERE date = ?
    GROUP BY category_id
  ''', [date]);
  return {
    for (final r in rows) r['category_id'] as int: (r['total'] as num).toInt(),
  };
}

/// 完了済みセッション（ended_at IS NOT NULL）の合計秒数
Future<int> getCompletedTotalSec(int categoryId, String date) async {
  final db = await getDb();
  final rows = await db.rawQuery('''
    SELECT SUM(duration_sec) AS total
    FROM sessions
    WHERE category_id = ? AND date = ? AND ended_at IS NOT NULL
  ''', [categoryId, date]);
  if (rows.isEmpty) return 0;
  return (rows.first['total'] as num?)?.toInt() ?? 0;
}

/// 月単位でdate -> {categoryId -> totalSec} を返す（ended_atがnullのものは除外）
Future<Map<String, Map<int, int>>> getDailySessions(String yearMonth) async {
  final db = await getDb();
  final rows = await db.rawQuery('''
    SELECT date, category_id, SUM(COALESCE(duration_sec, 0)) AS total
    FROM sessions
    WHERE date LIKE ? AND ended_at IS NOT NULL
    GROUP BY date, category_id
  ''', ['$yearMonth-%']);

  final result = <String, Map<int, int>>{};
  for (final r in rows) {
    final date = r['date'] as String;
    final catId = r['category_id'] as int;
    final total = (r['total'] as num).toInt();
    (result[date] ??= {})[catId] = total;
  }
  return result;
}
