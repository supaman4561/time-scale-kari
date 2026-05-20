// lib/db/schema.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database? _db;

Future<Database> getDb() async {
  _db ??= await openDatabase(
    join(await getDatabasesPath(), 'timescale.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('quota', 'limit')),
          color TEXT NOT NULL DEFAULT '#64b5f6',
          weekday_budget_min INTEGER NOT NULL DEFAULT 0,
          weekend_budget_min INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          ended_at INTEGER,
          duration_sec INTEGER,
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
        )
      ''');
    },
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
  );
  return _db!;
}
