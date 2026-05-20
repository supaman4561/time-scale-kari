# time-scale

1日の時間を「カテゴリ別持ち時間」として管理するモバイルアプリ。

## 機能

- **カテゴリ管理** — 仕事・自己研鑽・趣味など、自分でカテゴリを自由に定義
- **2種類のタイプ**
  - **ノルマ** — やりたくないこと（仕事など）。目標時間に達したらクリア
  - **上限** — やりたいこと（趣味など）。時間を使いすぎなければクリア（5分の猶予あり）
- **Start/Stopタイマー** — カテゴリを選んでタップするだけで時間を自動記録
- **通知** — 目標・上限時間に達したらpush通知
- **カレンダー** — 日ごとのクリア状況を一目で確認。日付タップで詳細表示
- **平日・休日の別設定** — 仕事がない休日は別の持ち時間を定義可能

## 技術スタック

- **React Native (Expo)**
- **Zustand** — 状態管理
- **expo-sqlite** — ローカルデータ永続化
- **expo-notifications** — push通知

## 開発

```bash
npm install
npx expo start
```

## 設計ドキュメント

[docs/superpowers/specs/2026-05-20-time-scale-design.md](docs/superpowers/specs/2026-05-20-time-scale-design.md)
