# Flutter Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** React Native版から機能を移植し、Flutter製のAndroid時間管理アプリを完成させる。

**Architecture:** Riverpodで状態管理、sqfliteでローカルDB、flutter_foreground_taskでバックグラウンドタイマー通知。画面はBottomNavigationBarで切り替え、DayDetail/CategoryEditへはNavigator.pushで遷移。

**Tech Stack:** Flutter 3.44.0, flutter_riverpod, sqflite, flutter_foreground_task, flutter_local_notifications

---

## Phase 1: Foundation

### Task 1: 依存パッケージの追加

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yamlに依存を追加**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  sqflite: ^2.4.2
  path: ^1.9.0
  flutter_foreground_task: ^8.14.0
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: パッケージを取得**

```bash
flutter pub get
```

Expected: `Got dependencies.` が表示される

- [ ] **Step 3: コミット**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add flutter dependencies"
```

---

### Task 2: テーマ定数

**Files:**
- Create: `lib/theme.dart`

- [ ] **Step 1: theme.dartを作成**

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F172A);
  static const card = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const textMain = Color(0xFFF1F5F9);
  static const textSub = Color(0xFF64748B);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.blue,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: AppColors.textSub,
    ),
  );
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/theme.dart
git commit -m "feat: add app theme constants"
```

---

### Task 3: モデル定義

**Files:**
- Create: `lib/models/category.dart`
- Create: `lib/models/session.dart`

- [ ] **Step 1: Category モデルを作成**

```dart
// lib/models/category.dart
class Category {
  final int? id;
  final String name;
  final String type; // 'quota' or 'limit'
  final String color;
  final int weekdayBudgetMin;
  final int weekendBudgetMin;
  final int sortOrder;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.weekdayBudgetMin,
    required this.weekendBudgetMin,
    required this.sortOrder,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        color: map['color'] as String,
        weekdayBudgetMin: map['weekday_budget_min'] as int,
        weekendBudgetMin: map['weekend_budget_min'] as int,
        sortOrder: map['sort_order'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'color': color,
        'weekday_budget_min': weekdayBudgetMin,
        'weekend_budget_min': weekendBudgetMin,
        'sort_order': sortOrder,
      };

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? color,
    int? weekdayBudgetMin,
    int? weekendBudgetMin,
    int? sortOrder,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color ?? this.color,
        weekdayBudgetMin: weekdayBudgetMin ?? this.weekdayBudgetMin,
        weekendBudgetMin: weekendBudgetMin ?? this.weekendBudgetMin,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
```

- [ ] **Step 2: Session モデルを作成**

```dart
// lib/models/session.dart
class Session {
  final int? id;
  final int categoryId;
  final String date; // YYYY-MM-DD
  final int startedAt; // Unix timestamp (seconds)
  final int? endedAt;
  final int? durationSec;

  const Session({
    this.id,
    required this.categoryId,
    required this.date,
    required this.startedAt,
    this.endedAt,
    this.durationSec,
  });

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int,
        date: map['date'] as String,
        startedAt: map['started_at'] as int,
        endedAt: map['ended_at'] as int?,
        durationSec: map['duration_sec'] as int?,
      );

  bool get isInProgress => endedAt == null;
}
```

- [ ] **Step 3: コミット**

```bash
git add lib/models/
git commit -m "feat: add Category and Session models"
```

---

### Task 4: ユーティリティ関数

**Files:**
- Create: `lib/utils/date_utils.dart`
- Create: `lib/utils/clear_check.dart`

- [ ] **Step 1: date_utils.dart を作成**

```dart
// lib/utils/date_utils.dart

/// ローカル日付を YYYY-MM-DD 形式で返す
String getLocalDateString([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// 土・日を休日と判定
bool isWeekend([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
}

/// 指定日の予算分数を返す（平日 or 休日）
int getBudgetForDate(int weekdayBudgetMin, int weekendBudgetMin, [DateTime? dt]) {
  return isWeekend(dt) ? weekendBudgetMin : weekdayBudgetMin;
}

/// 経過秒数を M:SS または H:MM:SS 形式にフォーマット
String formatDuration(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// 曜日の日本語表記
const _weekdayJa = ['月', '火', '水', '木', '金', '土', '日'];
String weekdayJa([DateTime? dt]) {
  final d = dt ?? DateTime.now();
  return _weekdayJa[d.weekday - 1];
}
```

- [ ] **Step 2: clear_check.dart を作成**

```dart
// lib/utils/clear_check.dart

/// カテゴリのクリア判定
/// quota: totalSec >= budgetMin * 60
/// limit: totalSec <= budgetMin * 60 + 300（5分猶予）
bool isCategoryCleared({
  required String type,
  required int budgetMin,
  required int totalSec,
}) {
  final budgetSec = budgetMin * 60;
  if (type == 'quota') return totalSec >= budgetSec;
  return totalSec <= budgetSec + 300;
}

/// 1日クリア判定（全カテゴリクリア、かつ1件以上）
bool isDayCleared(List<bool> results) {
  return results.isNotEmpty && results.every((r) => r);
}
```

- [ ] **Step 3: コミット**

```bash
git add lib/utils/
git commit -m "feat: add date_utils and clear_check utilities"
```

---

### Task 5: DBレイヤー

**Files:**
- Create: `lib/db/schema.dart`
- Create: `lib/db/categories_db.dart`
- Create: `lib/db/sessions_db.dart`

- [ ] **Step 1: schema.dart を作成**

```dart
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
```

- [ ] **Step 2: categories_db.dart を作成**

```dart
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
```

- [ ] **Step 3: sessions_db.dart を作成**

```dart
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

/// 計測中セッションを異常終了として閉じる（ended_at補完）
Future<void> closeAbandonedSessions() async {
  final db = await getDb();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final rows = await db.query('sessions', where: 'ended_at IS NULL');
  if (rows.isEmpty) return;
  // 最新1件以外を閉じる（最新は正常復元するので残す）
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

/// 指定日にデータがある日付のセットを月単位で取得
Future<Map<String, bool>> getDailyClearStatus(
  String yearMonth, // 'YYYY-MM'
  List<({String type, int budgetMin})> categories,
) async {
  final db = await getDb();
  final rows = await db.rawQuery('''
    SELECT date, category_id,
           SUM(COALESCE(duration_sec, 0)) AS total
    FROM sessions
    WHERE date LIKE ? AND ended_at IS NOT NULL
    GROUP BY date, category_id
  ''', ['$yearMonth-%']);

  // date -> categoryId -> totalSec
  final byDate = <String, Map<int, int>>{};
  for (final r in rows) {
    final date = r['date'] as String;
    final catId = r['category_id'] as int;
    final total = (r['total'] as num).toInt();
    (byDate[date] ??= {})[catId] = total;
  }

  // 各日のクリア判定は呼び出し元で行う（カテゴリリストが必要なため）
  return {for (final d in byDate.keys) d: byDate[d]!.isNotEmpty};
}
```

- [ ] **Step 4: コミット**

```bash
git add lib/db/
git commit -m "feat: add DB layer (schema, categories, sessions)"
```

---

## Phase 2: State & Services

### Task 6: カテゴリプロバイダー

**Files:**
- Create: `lib/providers/category_provider.dart`

- [ ] **Step 1: category_provider.dart を作成**

```dart
// lib/providers/category_provider.dart
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

  Future<void> update(Category category) async {
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
```

- [ ] **Step 2: コミット**

```bash
git add lib/providers/category_provider.dart
git commit -m "feat: add CategoryNotifier provider"
```

---

### Task 7: タイマープロバイダー

**Files:**
- Create: `lib/providers/timer_provider.dart`

- [ ] **Step 1: timer_provider.dart を作成**

```dart
// lib/providers/timer_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/categories_db.dart';
import '../db/sessions_db.dart';
import '../utils/date_utils.dart';

class TimerState {
  final int? activeSessionId;
  final int? activeCategoryId;
  final int? startedAt; // Unix seconds
  final int? budgetSec;

  const TimerState({
    this.activeSessionId,
    this.activeCategoryId,
    this.startedAt,
    this.budgetSec,
  });

  bool get isActive => activeSessionId != null;

  TimerState copyWith({
    int? activeSessionId,
    int? activeCategoryId,
    int? startedAt,
    int? budgetSec,
  }) =>
      TimerState(
        activeSessionId: activeSessionId ?? this.activeSessionId,
        activeCategoryId: activeCategoryId ?? this.activeCategoryId,
        startedAt: startedAt ?? this.startedAt,
        budgetSec: budgetSec ?? this.budgetSec,
      );

  static const empty = TimerState();
}

class TimerNotifier extends Notifier<TimerState> {
  @override
  TimerState build() => TimerState.empty;

  Future<void> start(int categoryId, int budgetSec) async {
    if (state.isActive) return;
    final date = getLocalDateString();
    final sessionId = await startSession(categoryId, date);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    state = TimerState(
      activeSessionId: sessionId,
      activeCategoryId: categoryId,
      startedAt: now,
      budgetSec: budgetSec,
    );
  }

  Future<void> stop() async {
    if (!state.isActive) return;
    await stopSession(state.activeSessionId!);
    state = TimerState.empty;
  }

  /// 起動時復元
  Future<void> restore() async {
    await closeAbandonedSessions();
    final session = await getInProgressSession();
    if (session == null) return;
    // 日付が変わっていたら閉じる
    final today = getLocalDateString();
    if (session.date != today) {
      await stopSession(session.id!);
      return;
    }
    // カテゴリのbudgetSecを取得する
    final cats = await fetchCategories();
    final cat = cats.where((c) => c.id == session.categoryId).firstOrNull;
    final now = DateTime.now();
    final budgetMin = cat != null
        ? getBudgetForDate(cat.weekdayBudgetMin, cat.weekendBudgetMin, now)
        : 0;
    state = TimerState(
      activeSessionId: session.id,
      activeCategoryId: session.categoryId,
      startedAt: session.startedAt,
      budgetSec: budgetMin * 60,
    );
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
```

- [ ] **Step 2: コミット**

```bash
git add lib/providers/timer_provider.dart
git commit -m "feat: add TimerNotifier provider"
```

---

### Task 8: フォアグラウンドサービス + 通知

**Files:**
- Create: `lib/services/foreground_task_handler.dart`
- Create: `lib/services/notification_service.dart`

- [ ] **Step 1: notification_service.dart を作成**

```dart
// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(const InitializationSettings(android: android));
}

Future<void> showBudgetNotification({
  required String categoryName,
  required bool isQuota,
}) async {
  final body = isQuota ? '予定時間に達しました' : '上限時間を超えました';
  await _plugin.show(
    1,
    categoryName,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_channel',
        '予算通知',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}
```

- [ ] **Step 2: foreground_task_handler.dart を作成**

```dart
// lib/services/foreground_task_handler.dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/date_utils.dart';

/// vm:entry-point が必須（別Isolateで実行される）
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

class TimerTaskHandler extends TaskHandler {
  int? _startedAt;
  int? _budgetSec;
  String _categoryName = '';
  bool _budgetNotified = false;
  final _notifPlugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 初期データを受信するまで待機（onReceiveDataで設定）
    await _notifPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      _startedAt = data['started_at'] as int?;
      _budgetSec = data['budget_sec'] as int?;
      _categoryName = data['category_name'] as String? ?? '';
      _budgetNotified = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_startedAt == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now - _startedAt!;

    FlutterForegroundTask.updateService(
      notificationTitle: '$_categoryName 計測中',
      notificationText: formatDuration(elapsed),
    );

    // 予算到達通知（1回だけ）
    if (!_budgetNotified && _budgetSec != null && elapsed >= _budgetSec!) {
      _budgetNotified = true;
      _notifPlugin.show(
        1,
        _categoryName,
        '予定時間に達しました',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_channel',
            '予算通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// フォアグラウンドサービスの初期化（main()で一度だけ呼ぶ）
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'timer_channel',
      channelName: 'タイマー',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
}

Future<void> startForegroundTimer({
  required String categoryName,
  required int startedAt,
  required int budgetSec,
}) async {
  await FlutterForegroundTask.startService(
    serviceId: 100,
    notificationTitle: '$categoryName 計測中',
    notificationText: '0:00',
    callback: startCallback,
  );
  // データを TaskHandler へ送信
  FlutterForegroundTask.sendDataToTask({
    'started_at': startedAt,
    'budget_sec': budgetSec,
    'category_name': categoryName,
  });
}

Future<void> stopForegroundTimer() async {
  await FlutterForegroundTask.stopService();
}
```

- [ ] **Step 3: コミット**

```bash
git add lib/services/
git commit -m "feat: add foreground task handler and notification service"
```

---

## Phase 3: Widgets

### Task 9: ProgressBar ウィジェット

**Files:**
- Create: `lib/widgets/progress_bar.dart`

- [ ] **Step 1: progress_bar.dart を作成**

```dart
// lib/widgets/progress_bar.dart
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0+
  final Color color;

  const ProgressBar({super.key, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * progress.clamp(0.0, 1.0));
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withAlpha(180)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/widgets/progress_bar.dart
git commit -m "feat: add ProgressBar widget"
```

---

### Task 10: CategoryCard ウィジェット

**Files:**
- Create: `lib/widgets/category_card.dart`

- [ ] **Step 1: category_card.dart を作成**

```dart
// lib/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import 'progress_bar.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final int totalSec;
  final bool isActive;
  final bool isAnyActive;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.totalSec,
    required this.isActive,
    required this.isAnyActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgetMin = getBudgetForDate(
      category.weekdayBudgetMin,
      category.weekendBudgetMin,
      now,
    );
    final budgetSec = budgetMin * 60;
    final cleared = isCategoryCleared(
      type: category.type,
      budgetMin: budgetMin,
      totalSec: totalSec,
    );
    final isOver = category.type == 'limit' && totalSec > budgetSec + 300;
    final dotColor = _parseColor(category.color);
    final progress = budgetSec > 0 ? totalSec / budgetSec : 0.0;

    final isDisabled = isAnyActive && !isActive;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: cleared
                ? Border.all(color: const Color(0xFF10B981).withAlpha(100), width: 1)
                : isOver
                    ? Border.all(color: const Color(0xFFEF4444).withAlpha(100), width: 1)
                    : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // カラードット（グロー効果）
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: dotColor.withAlpha(160), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (cleared && !isOver) _badge('CLEAR', const Color(0xFF10B981)),
                  if (isOver) _badge('超過', const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatMin(totalSec)} / ${budgetMin}分',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProgressBar(progress: progress, color: dotColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );

  String _formatMin(int sec) {
    final m = sec ~/ 60;
    return '$m分';
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(0xFF000000 | value);
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/widgets/category_card.dart
git commit -m "feat: add CategoryCard widget"
```

---

### Task 11: TimerBanner ウィジェット

**Files:**
- Create: `lib/widgets/timer_banner.dart`

- [ ] **Step 1: timer_banner.dart を作成**

```dart
// lib/widgets/timer_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

class TimerBanner extends StatefulWidget {
  final String categoryName;
  final int startedAt; // Unix seconds
  final VoidCallback onStop;

  const TimerBanner({
    super.key,
    required this.categoryName,
    required this.startedAt,
    required this.onStop,
  });

  @override
  State<TimerBanner> createState() => _TimerBannerState();
}

class _TimerBannerState extends State<TimerBanner> {
  late Timer _timer;
  late int _elapsed;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateElapsed);
    });
  }

  void _updateElapsed() {
    _elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - widget.startedAt;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '計測中 — ${widget.categoryName}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(_elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onStop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                border: Border.all(color: Colors.white.withAlpha(60)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '停止',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/widgets/timer_banner.dart
git commit -m "feat: add TimerBanner widget with live countdown"
```

---

### Task 12: CalendarGrid ウィジェット

**Files:**
- Create: `lib/widgets/calendar_grid.dart`

- [ ] **Step 1: calendar_grid.dart を作成**

```dart
// lib/widgets/calendar_grid.dart
import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

enum DayStatus { clear, notClear, noData, today }

class CalendarGrid extends StatelessWidget {
  final DateTime month; // その月を表すDateTime（dayは1）
  final Map<String, DayStatus> statusMap; // 'YYYY-MM-DD' -> status
  final void Function(String date) onDayTap;

  const CalendarGrid({
    super.key,
    required this.month,
    required this.statusMap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = getLocalDateString();
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 月曜始まり (weekday: Mon=1, Sun=7)
    final startOffset = (firstDay.weekday - 1) % 7;

    final cells = <Widget>[
      for (final label in ['月', '火', '水', '木', '金', '土', '日'])
        Center(
          child: Text(label,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
        ),
      for (var i = 0; i < startOffset; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          date: '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
          isToday: todayStr ==
              '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
          status: statusMap['${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}'] ??
              DayStatus.noData,
          onTap: onDayTap,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String date;
  final bool isToday;
  final DayStatus status;
  final void Function(String) onTap;

  const _DayCell({
    required this.day,
    required this.date,
    required this.isToday,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? dotColor;
    if (status == DayStatus.clear) dotColor = const Color(0xFF10B981);
    if (status == DayStatus.notClear) dotColor = const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isToday ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            if (dotColor != null) ...[
              const SizedBox(height: 2),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/widgets/calendar_grid.dart
git commit -m "feat: add CalendarGrid widget"
```

---

## Phase 4: Screens

### Task 13: main.dart とアプリ骨格

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: main.dart を書き換える**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db/schema.dart';
import 'providers/timer_provider.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'services/foreground_task_handler.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initForegroundTask();
  await initNotifications();
  await getDb(); // DBを初期化
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeScale',
      theme: buildAppTheme(),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    TodayScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 起動時にセッション復元 → フォアグラウンドサービスへデータ再送
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(timerProvider.notifier).restore();
      final timer = ref.read(timerProvider);
      if (timer.isActive && timer.startedAt != null) {
        final cats = ref.read(categoryProvider).valueOrNull ?? [];
        final cat = cats.firstWhere(
          (c) => c.id == timer.activeCategoryId,
          orElse: () => cats.first,
        );
        try {
          await startForegroundTimer(
            categoryName: cat.name,
            startedAt: timer.startedAt!,
            budgetSec: timer.budgetSec ?? 0,
          );
        } catch (e) {
          debugPrint('ForegroundService restore error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'TODAY'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'CALENDAR'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETTINGS'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/main.dart
git commit -m "feat: add main app scaffold with bottom navigation"
```

---

### Task 14: TodayScreen

**Files:**
- Create: `lib/screens/today_screen.dart`

- [ ] **Step 1: today_screen.dart を作成**

```dart
// lib/screens/today_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/timer_provider.dart';
import '../services/foreground_task_handler.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import '../widgets/category_card.dart';
import '../widgets/timer_banner.dart';
import '../theme.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Map<int, int> _totalByCategory = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final today = getLocalDateString();
    final totals = await getTotalSecByCategory(today);
    if (mounted) setState(() => _totalByCategory = totals);
  }

  Future<void> _handleTap(Category category) async {
    final timer = ref.read(timerProvider);
    final now = DateTime.now();
    final budgetMin = getBudgetForDate(
      category.weekdayBudgetMin,
      category.weekendBudgetMin,
      now,
    );

    if (timer.activeCategoryId == category.id) {
      // 停止
      await stopForegroundTimer();
      await ref.read(timerProvider.notifier).stop();
    } else {
      // 開始
      final budgetSec = budgetMin * 60;
      await ref.read(timerProvider.notifier).start(category.id!, budgetSec);
      final startedAt = ref.read(timerProvider).startedAt!;
      try {
        await startForegroundTimer(
          categoryName: category.name,
          startedAt: startedAt,
          budgetSec: budgetSec,
        );
      } catch (e) {
        debugPrint('ForegroundService error: $e');
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    await _refresh();
  }

  Future<void> _handleStop() async {
    await stopForegroundTimer();
    await ref.read(timerProvider.notifier).stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final timer = ref.watch(timerProvider);
    final now = DateTime.now();
    final today = getLocalDateString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '$today（${weekdayJa()}）',
                style: const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (categories) {
                final activeCategory = categories.firstWhere(
                  (c) => c.id == timer.activeCategoryId,
                  orElse: () => categories.isEmpty
                      ? const Category(
                          name: '', type: 'quota', color: '#64b5f6',
                          weekdayBudgetMin: 0, weekendBudgetMin: 0, sortOrder: 0)
                      : categories.first,
                );

                return Expanded(
                  child: Column(
                    children: [
                      if (timer.isActive && timer.startedAt != null)
                        TimerBanner(
                          categoryName: timer.activeCategoryId != null
                              ? categories
                                  .firstWhere((c) => c.id == timer.activeCategoryId,
                                      orElse: () => activeCategory)
                                  .name
                              : '',
                          startedAt: timer.startedAt!,
                          onStop: _handleStop,
                        ),
                      Expanded(
                        child: categories.isEmpty
                            ? const Center(
                                child: Text(
                                  '設定画面からカテゴリを追加してください',
                                  style: TextStyle(color: AppColors.textSub),
                                ),
                              )
                            : ListView.builder(
                                itemCount: categories.length,
                                itemBuilder: (context, i) {
                                  final cat = categories[i];
                                  return CategoryCard(
                                    category: cat,
                                    totalSec: _totalByCategory[cat.id] ?? 0,
                                    isActive: cat.id == timer.activeCategoryId,
                                    isAnyActive: timer.isActive,
                                    onTap: () => _handleTap(cat),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/screens/today_screen.dart
git commit -m "feat: add TodayScreen"
```

---

### Task 15: CalendarScreen + DayDetailScreen

**Files:**
- Create: `lib/screens/calendar_screen.dart`
- Create: `lib/screens/day_detail_screen.dart`

- [ ] **Step 1: day_detail_screen.dart を作成**

```dart
// lib/screens/day_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../providers/category_provider.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import '../widgets/progress_bar.dart';
import '../theme.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final String date; // YYYY-MM-DD

  const DayDetailScreen({super.key, required this.date});

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  Map<int, int> _totals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await getTotalSecByCategory(widget.date);
    if (mounted) setState(() { _totals = totals; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final dt = DateTime.tryParse(widget.date) ?? DateTime.now();
    final label = '${widget.date}（${weekdayJa(dt)}）';

    return Scaffold(
      appBar: AppBar(
        title: Text(label, style: const TextStyle(fontSize: 15)),
        backgroundColor: AppColors.card,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(child: Text('カテゴリがありません'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final totalSec = _totals[cat.id] ?? 0;
                    final isWeekend = dt.weekday == DateTime.saturday ||
                        dt.weekday == DateTime.sunday;
                    final budgetMin = isWeekend
                        ? cat.weekendBudgetMin
                        : cat.weekdayBudgetMin;
                    final cleared = isCategoryCleared(
                      type: cat.type,
                      budgetMin: budgetMin,
                      totalSec: totalSec,
                    );
                    final dotColor = _parseColor(cat.color);
                    final progress = budgetMin > 0 ? totalSec / (budgetMin * 60) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: cleared
                            ? Border.all(color: AppColors.green.withAlpha(100))
                            : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: dotColor.withAlpha(160), blurRadius: 6)],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(cat.name,
                                style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600))),
                              if (cleared)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withAlpha(40),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text('CLEAR',
                                    style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              const SizedBox(width: 8),
                              Text('${totalSec ~/ 60}分 / ${budgetMin}分',
                                style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ProgressBar(progress: progress, color: dotColor),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }
}
```

- [ ] **Step 2: calendar_screen.dart を作成**

```dart
// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/sessions_db.dart';
import '../providers/category_provider.dart';
import '../utils/clear_check.dart';
import '../utils/date_utils.dart';
import '../widgets/calendar_grid.dart';
import '../theme.dart';
import 'day_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime.now();
  Map<String, DayStatus> _statusMap = {};

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final yearMonth =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final categoriesAsync = ref.read(categoryProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    // 月のセッション集計
    final db = await getDailySessions(yearMonth);

    final statusMap = <String, DayStatus>{};
    final today = getLocalDateString();
    final todayDt = DateTime.now();

    for (final entry in db.entries) {
      final dateStr = entry.key;
      final totals = entry.value;
      final dt = DateTime.tryParse(dateStr) ?? todayDt;
      final isWeekend =
          dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

      final results = categories.map((cat) {
        final budgetMin =
            isWeekend ? cat.weekendBudgetMin : cat.weekdayBudgetMin;
        final totalSec = totals[cat.id] ?? 0;
        return isCategoryCleared(
            type: cat.type, budgetMin: budgetMin, totalSec: totalSec);
      }).toList();

      final cleared = isDayCleared(results);
      statusMap[dateStr] = cleared ? DayStatus.clear : DayStatus.notClear;
    }

    if (mounted) setState(() => _statusMap = statusMap);
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
    _loadMonth();
  }

  void _nextMonth() {
    setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textSub),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_month.year}年 ${_month.month}月',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textSub),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            CalendarGrid(
              month: _month,
              statusMap: _statusMap,
              onDayTap: (date) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayDetailScreen(date: date),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: sessions_db.dart の getDailyClearStatus を getDailySessions に置き換える**

Task 5 で追加した `getDailyClearStatus` 関数を削除し、代わりに `getDailySessions` を追加する（CalendarScreen で使う戻り値型が異なるため）。

`getDailyClearStatus` を削除して以下に置き換え：

```dart
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
```

- [ ] **Step 4: コミット**

```bash
git add lib/screens/calendar_screen.dart lib/screens/day_detail_screen.dart lib/db/sessions_db.dart
git commit -m "feat: add CalendarScreen and DayDetailScreen"
```

---

### Task 16: SettingsScreen

**Files:**
- Create: `lib/screens/settings_screen.dart`

- [ ] **Step 1: settings_screen.dart を作成**

```dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../theme.dart';
import 'category_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
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

  Color _parseColor(String hex) {
    try {
      return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }
}
```

- [ ] **Step 2: コミット**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: add SettingsScreen with reorderable list"
```

---

### Task 17: CategoryEditScreen

**Files:**
- Create: `lib/screens/category_edit_screen.dart`

- [ ] **Step 1: category_edit_screen.dart を作成**

```dart
// lib/screens/category_edit_screen.dart
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
      await notifier.update(widget.category!.copyWith(
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
      Navigator.pop(context);
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
```

- [ ] **Step 2: コミット**

```bash
git add lib/screens/category_edit_screen.dart
git commit -m "feat: add CategoryEditScreen"
```

---

## Phase 5: Android Configuration

### Task 18: AndroidManifest とパーミッション

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: AndroidManifest.xml にパーミッションとサービスを追加**

`<manifest>` タグの直下（`<application>` の前）に追加：

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

`<application>` タグの中（`<activity>` と同列）に追加：

```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="specialUse"
    android:exported="false">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="time tracking"/>
</service>
```

- [ ] **Step 2: コミット**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat: add Android permissions and foreground service declaration"
```

---

### Task 19: ビルドと動作確認

- [ ] **Step 1: 静的解析**

```bash
flutter analyze
```

Expected: `No issues found!` またはワーニングのみ（エラーなし）

- [ ] **Step 2: デバイスへビルド＆インストール**

```bash
flutter run
```

Expected: アプリが起動し、BottomNavigationBarが表示される

- [ ] **Step 3: 動作チェックリスト**

手動で以下を確認：

- [ ] カテゴリ追加（Settings → ＋ボタン）
- [ ] Today画面にカードが表示される
- [ ] カードタップでタイマー開始、バナーが表示される
- [ ] バックグラウンドに移行してもタイマー通知が更新される
- [ ] 停止でバナーが消え、進捗が更新される
- [ ] Calendar画面でグリッドが表示される
- [ ] 日付タップでDayDetail画面に遷移する
- [ ] カテゴリ削除時に確認ダイアログが出る
- [ ] タイマー計測中にアプリを終了→再起動してもタイマー状態が復元される

- [ ] **Step 4: 最終コミット**

```bash
git add .
git commit -m "feat: complete Flutter rewrite of time-scale-kari"
```
