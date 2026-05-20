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
  final int previousTotalSec;
  final String categoryType;

  const TimerState({
    this.activeSessionId,
    this.activeCategoryId,
    this.startedAt,
    this.budgetSec,
    this.previousTotalSec = 0,
    this.categoryType = 'quota',
  });

  bool get isActive => activeSessionId != null;

  TimerState copyWith({
    int? activeSessionId,
    int? activeCategoryId,
    int? startedAt,
    int? budgetSec,
    int? previousTotalSec,
    String? categoryType,
  }) =>
      TimerState(
        activeSessionId: activeSessionId ?? this.activeSessionId,
        activeCategoryId: activeCategoryId ?? this.activeCategoryId,
        startedAt: startedAt ?? this.startedAt,
        budgetSec: budgetSec ?? this.budgetSec,
        previousTotalSec: previousTotalSec ?? this.previousTotalSec,
        categoryType: categoryType ?? this.categoryType,
      );

  static const empty = TimerState(previousTotalSec: 0, categoryType: 'quota');
}

class TimerNotifier extends Notifier<TimerState> {
  @override
  TimerState build() => TimerState.empty;

  Future<void> start(int categoryId, int budgetSec, String categoryType) async {
    if (state.isActive) return;
    final date = getLocalDateString();
    final previousTotal = await getCompletedTotalSec(categoryId, date);
    final sessionId = await startSession(categoryId, date);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    state = TimerState(
      activeSessionId: sessionId,
      activeCategoryId: categoryId,
      startedAt: now,
      budgetSec: budgetSec,
      previousTotalSec: previousTotal,
      categoryType: categoryType,
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
    final previousTotal = await getCompletedTotalSec(session.categoryId, today);
    state = TimerState(
      activeSessionId: session.id,
      activeCategoryId: session.categoryId,
      startedAt: session.startedAt,
      budgetSec: budgetMin * 60,
      previousTotalSec: previousTotal,
      categoryType: cat?.type ?? 'quota',
    );
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
