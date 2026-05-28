# time-scale

1日の時間を「カテゴリ別持ち時間」として管理するモバイルアプリ。

## 機能

- **カテゴリ管理** — 仕事・自己研鑽・趣味など、自分でカテゴリを自由に定義
- **2種類のタイプ**
  - **ノルマ** — やりたくないこと（仕事など）。目標時間に達したらクリア
  - **上限** — やりたいこと（趣味など）。時間を使いすぎなければクリア（5分の猶予あり）
- **Start/Stopタイマー** — カテゴリを選んでタップするだけで時間を自動記録。計測中に別カテゴリをタップで即切り替え
- **バックグラウンド計測** — アプリを閉じていても通知欄にリアルタイムで計測時間を表示
- **アラーム通知** — 目標・上限時間に達したらpush通知
- **対象曜日の設定** — カテゴリごとに計測対象とする曜日を個別に選択
- **カレンダー** — 日ごとのクリア状況・カテゴリ別達成度を一目で確認。日付タップで詳細表示
- **24時間タイムラインチャート** — 1日のどの時間帯に何をしたかを円グラフで可視化。タップ/スワイプで詳細確認
- **Health Connect 連携** — 睡眠データをタイムラインチャートに反映（Fitbit / Google Health 対応）

## 技術スタック

- **Flutter 3** — クロスプラットフォームUIフレームワーク
- **flutter_riverpod** — 状態管理
- **sqflite** — ローカルSQLiteデータベース
- **flutter_foreground_task** — バックグラウンドタイマー・フォアグラウンドサービス
- **flutter_local_notifications** — push通知
- **health** — Health Connect（Android）連携
- **shared_preferences** — 設定の永続化

## 開発

```bash
flutter pub get
flutter run
```

## 設計ドキュメント

- [仕様書](docs/superpowers/specs/2026-05-21-flutter-rewrite-design.md)
- [実装計画](docs/superpowers/plans/2026-05-21-flutter-rewrite.md)
