# CLAUDE.md

## プロジェクト概要

1日の時間をカテゴリ別に管理するReact Nativeモバイルアプリ。

## 技術スタック

- React Native (Expo)
- Zustand（状態管理）
- expo-sqlite（ローカルDB）
- expo-notifications（通知）
- TypeScript

## ディレクトリ構成（予定）

```
src/
  screens/        # 画面コンポーネント（Today, Calendar, Settings）
  components/     # 共通UIコンポーネント
  store/          # Zustandストア
  db/             # SQLiteスキーマ・クエリ
  hooks/          # カスタムフック
  utils/          # 日付計算・クリア判定などのユーティリティ
```

## データモデル

### categories テーブル
- `type`: `quota`（ノルマ/加算式）または `limit`（上限/減算式）
- `weekday_budget_min` / `weekend_budget_min`: 分単位

### sessions テーブル
- `ended_at` が null のレコードが「計測中」を意味する
- `date` は `YYYY-MM-DD` 形式のローカル日付

## ビジネスロジック

### クリア判定

- **ノルマ（quota）**: `合計秒数 >= budget_min * 60` でクリア
- **上限（limit）**: `合計秒数 <= budget_min * 60 + 300`（5分猶予）でクリア
- **1日クリア**: 全カテゴリがクリア状態のとき

### 休日判定

- 現在は土・日を休日として扱う（祝日APIは将来対応）
- 休日は `weekend_budget_min` を使用

## UIデザイン方針

- モダンなデザイン。角丸（border-radius）を積極的に使う
- カードUI中心。各カテゴリ・セクションはカード形式で視覚的に分離する
- ダークテーマベースで検討（ブレインストーミング時のモックアップ参照）
- シャドウや微細なグラデーションを使ってUI要素に奥行きを出す

## 開発上の注意

- カテゴリは初期状態で空。ユーザーが設定画面から追加する
- タスク（サブカテゴリ）は存在しない。セッションはカテゴリに直接紐付く
- ローカルストレージ優先。将来的にGoogleログイン・クラウド同期を追加予定のため、データ層は疎結合に保つ
- 計測中セッション（`ended_at = null`）はアプリ起動時に必ず確認し、異常終了していたら適切に処理する
