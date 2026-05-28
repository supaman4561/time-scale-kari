# Flutter Rewrite Design — time-scale-kari

Date: 2026-05-21

## Overview

1日の時間をカテゴリ別に管理するFlutterモバイルアプリ。React Native/Expo版からの移植。Androidをターゲットとする。

## Technology Stack

| Purpose | Package |
|---------|---------|
| State management | flutter_riverpod |
| Local DB | sqflite |
| Navigation | Navigator (standard) |
| Background timer | flutter_foreground_task |
| Notifications | flutter_local_notifications |

## Directory Structure

```
lib/
  main.dart                  # エントリーポイント、DB初期化、プロバイダースコープ
  db/
    schema.dart              # DB初期化・接続
    categories_db.dart       # カテゴリCRUD
    sessions_db.dart         # セッションCRUD
  models/
    category.dart            # Categoryモデル
    session.dart             # Sessionモデル
  providers/
    category_provider.dart   # カテゴリ一覧のRiverpodプロバイダー
    timer_provider.dart      # タイマー状態のRiverpodプロバイダー
  screens/
    today_screen.dart        # 今日のカテゴリ一覧・タイマー操作
    calendar_screen.dart     # 月グリッドカレンダー
    day_detail_screen.dart   # 特定日のカテゴリ別実績
    settings_screen.dart     # カテゴリ一覧管理
    category_edit_screen.dart # カテゴリ追加・編集
  widgets/
    category_card.dart       # カテゴリカード（進捗バー付き）
    timer_banner.dart        # 計測中バナー（グラデーション）
    progress_bar.dart        # プログレスバー
    calendar_grid.dart       # 月グリッド
  utils/
    clear_check.dart         # クリア判定ロジック
    date_utils.dart          # 日付計算・ローカル日付文字列
```

## Data Models

### categories テーブル

```sql
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('quota', 'limit')),
  color TEXT NOT NULL DEFAULT '#64b5f6',
  weekday_budget_min INTEGER NOT NULL DEFAULT 0,
  weekend_budget_min INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);
```

### sessions テーブル

```sql
CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER,
  duration_sec INTEGER,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);
```

- `ended_at` が null のレコードが「計測中」
- `date` は `YYYY-MM-DD` 形式のローカル日付
- `started_at` / `ended_at` はUnixタイムスタンプ（秒）

## Business Logic

### クリア判定

```dart
// quota（ノルマ）: 合計秒数が予算以上でクリア
bool isCleared = totalSec >= budgetMin * 60;

// limit（上限）: 合計秒数が予算+5分猶予以内でクリア
bool isCleared = totalSec <= budgetMin * 60 + 300;
```

### 1日クリア

全カテゴリがクリア状態のとき。カテゴリが0件の場合はクリアとしない。

### 休日判定

土・日を休日とし、`weekend_budget_min` を使用。祝日は将来対応。

### 起動時セッション復元

`ended_at = null` のセッションがあれば、タイマー状態を復元する。異常終了（日付が変わっているなど）の場合は `ended_at` を補完してセッションを閉じる。

## Screens

### TodayScreen

- 今日の日付と曜日を表示
- 計測中の場合はグラデーションバナーを表示（経過時間を毎秒更新）
- カテゴリ一覧をカードで表示（進捗バー、クリア状態バッジ）
- カードタップ → 計測開始/停止
- 計測中に別カテゴリはタップ不可

### CalendarScreen

- 月グリッド表示（7列）
- 各日にドット表示: 緑=1日クリア、赤=未クリア、なし=データなし
- 日付セルタップ → DayDetailScreenへ遷移
- 月切り替えボタン（前月/翌月）

### DayDetailScreen

- 指定日のカテゴリ別実績を読み取り専用で表示
- 各カテゴリの合計時間・クリア状況
- 当日をカレンダーからタップして遷移した場合も同じDayDetailScreenを表示（タイマー操作はTodayScreenのみ）

### SettingsScreen

- カテゴリ一覧（`ReorderableListView` でドラッグ&ドロップ並び替え）
- 並び替え確定時に全カテゴリの `sort_order` を 0, 1, 2... と振り直してDB更新
- タップ → CategoryEditScreen
- 追加ボタン → CategoryEditScreen（新規）

### CategoryEditScreen

- 名前、type（quota/limit）、色、平日予算、休日予算を入力
- 保存・削除
- 削除時は「このカテゴリの全セッションも削除されます」の確認ダイアログを表示

## UI Design

### テーマ

- 背景: `#0f172a`
- カード背景: `#1e293b`
- テキスト: `#f1f5f9`（メイン）、`#64748b`（サブ）
- ボーダー: `#334155`

### タイマーバナー

- グラデーション: `#3b82f6` → `#8b5cf6`
- ボックスシャドウ: `rgba(99,102,241,0.4)`
- 経過時間フォーマット: 1時間未満は `M:SS`、1時間以上は `H:MM:SS`

### カテゴリカード

- カテゴリ固有カラーのドット（グロー効果付き）
- プログレスバーはカテゴリカラーのグラデーション
- クリア時: 緑ボーダー + CLEARバッジ
- 上限超過時: 赤ボーダー + 超過バッジ

### カレンダーグリッド

- 各日セル: `#1e293b` 背景、角丸
- 今日: `#3b82f6` 背景
- クリアドット: 緑 `#10b981`、未クリアドット: 赤 `#ef4444`
- 注釈（凡例）なし

### ナビゲーション

- BottomNavigationBar: TODAY / CALENDAR / SETTINGS
- 画面間遷移は `Navigator.push`

## Background Timer

`flutter_foreground_task` を使い、Androidフォアグラウンドサービスを起動する。

- タイマー開始時: サービス起動、通知に `カテゴリ名 計測中 — 0:00` を表示
- 1秒ごとに経過時間を通知テキストに更新（例: `読書 計測中 — 12:34`）
- タイマー停止時: サービス停止

フォアグラウンドサービスの通知は「経過時間の表示」専用。予算到達通知とは別チャネル。

## Notifications

`flutter_local_notifications` を使い、予算時間到達時にローカル通知を1回送る。

- quota: 経過時間が `budgetMin * 60` 秒に達したとき通知
- limit: 経過時間が `budgetMin * 60` 秒を超えたとき通知

**通知の責務分担:**
- フォアグラウンドサービスのTaskHandler内で毎秒カウントし、予算到達を検出したら `flutter_local_notifications` で通知を送る
- アプリがバックグラウンドでもフォアグラウンドサービスは動作し続けるため、通知はRiverpodプロバイダーではなくTaskHandler内で完結させる
- これにより `flutter_foreground_task`（毎秒更新 + 予算通知トリガー）と `flutter_local_notifications`（通知表示）の役割が分離される

## Error Handling

- DB操作はすべて非同期（`Future`）で処理し、UIスレッドをブロックしない
- フォアグラウンドサービスの起動失敗はログ出力し、UI側には影響させない
- アプリ起動時に `ended_at = null` が複数あった場合（異常ケース）は最新のセッション以外を閉じる

## Out of Scope

- iOS対応（将来対応）
- 祝日API
- Googleログイン・クラウド同期
- テスト（将来追加）
