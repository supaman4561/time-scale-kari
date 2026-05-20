# time-scale 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** カテゴリ別持ち時間管理モバイルアプリ（React Native / Expo）を実装する

**Architecture:** SQLiteをローカルDBとして使いセッションを永続化。Zustandで画面間の状態を共有。ボトムタブ3画面（今日・カレンダー・設定）構成。

**Tech Stack:** Expo (React Native), TypeScript, Zustand, expo-sqlite v14, expo-notifications, React Navigation v6

---

## ファイル構成

```
src/
  db/
    schema.ts           - DB初期化・接続
    categories.ts       - カテゴリCRUD
    sessions.ts         - セッションCRUD
    __tests__/
      categories.test.ts
      sessions.test.ts
  store/
    categoryStore.ts    - カテゴリ一覧のZustandストア
    timerStore.ts       - アクティブタイマー状態のZustandストア
    __tests__/
      categoryStore.test.ts
      timerStore.test.ts
  utils/
    clearCheck.ts       - クリア判定ロジック
    dateUtils.ts        - 日付ユーティリティ
    notifications.ts    - 通知スケジュール・キャンセル
    __tests__/
      clearCheck.test.ts
      dateUtils.test.ts
  theme.ts              - 色・角丸定数
  navigation/
    AppNavigator.tsx    - BottomTabナビゲーター
  screens/
    TodayScreen.tsx
    CalendarScreen.tsx
    DayDetailScreen.tsx
    SettingsScreen.tsx
    CategoryEditScreen.tsx
  components/
    ProgressBar.tsx
    CategoryCard.tsx
    TimerBanner.tsx
    CalendarGrid.tsx
App.tsx
```

---

## Task 1: Expo プロジェクト初期化

**Files:**
- Create: `package.json`, `app.json`, `tsconfig.json`, `babel.config.js`, `App.tsx`

- [ ] **Step 1: 既存ファイルをバックアップ**

```bash
cp README.md /tmp/README.md.bak
cp CLAUDE.md /tmp/CLAUDE.md.bak
cp -r docs /tmp/docs.bak
```

- [ ] **Step 2: Expo プロジェクトを初期化**

```bash
npx create-expo-app@latest . --template blank-typescript
```

ディレクトリが空でないと警告が出る場合は `y` で続行。

- [ ] **Step 3: バックアップを復元**

```bash
cp /tmp/README.md.bak README.md
cp /tmp/CLAUDE.md.bak CLAUDE.md
cp -r /tmp/docs.bak/* docs/
```

- [ ] **Step 4: 追加依存関係をインストール**

```bash
npx expo install expo-sqlite expo-notifications expo-device
npx expo install @react-navigation/native @react-navigation/bottom-tabs @react-navigation/native-stack
npx expo install react-native-screens react-native-safe-area-context
npm install zustand
npm install --save-dev @testing-library/react-native @testing-library/jest-native jest-expo
```

- [ ] **Step 5: 起動確認**

```bash
npx expo start
```

Expected: Metro Bundler が起動し QR コードが表示される。エラーなし。Ctrl+C で停止。

- [ ] **Step 6: コミット**

```bash
git add -A
git commit -m "feat: initialize Expo TypeScript project with dependencies"
```

---

## Task 2: テスト環境セットアップ

**Files:**
- Modify: `package.json` (jest config)
- Create: `jest.config.js`
- Create: `__mocks__/expo-sqlite.ts`

- [ ] **Step 1: jest.config.js を作成**

```js
// jest.config.js
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterFramework: ['@testing-library/jest-native/extend-expect'],
  moduleNameMapper: {
    '^expo-sqlite$': '<rootDir>/__mocks__/expo-sqlite.ts',
    '^expo-notifications$': '<rootDir>/__mocks__/expo-notifications.ts',
  },
  testPathIgnorePatterns: ['/node_modules/', '/android/', '/ios/'],
};
```

- [ ] **Step 2: expo-sqlite モックを作成**

```typescript
// __mocks__/expo-sqlite.ts
export const mockDbInstance = {
  execSync: jest.fn(),
  runSync: jest.fn(() => ({ lastInsertRowId: 1, changes: 1 })),
  getAllSync: jest.fn(() => []),
  getFirstSync: jest.fn(() => null),
};

export const openDatabaseSync = jest.fn(() => mockDbInstance);
```

- [ ] **Step 3: expo-notifications モックを作成**

```typescript
// __mocks__/expo-notifications.ts
export const requestPermissionsAsync = jest.fn(() =>
  Promise.resolve({ status: 'granted' })
);
export const scheduleNotificationAsync = jest.fn(() =>
  Promise.resolve('mock-notification-id')
);
export const cancelScheduledNotificationAsync = jest.fn(() =>
  Promise.resolve()
);
export const setNotificationHandler = jest.fn();
export const AndroidImportance = { MAX: 5 };
export const setNotificationChannelAsync = jest.fn();
```

- [ ] **Step 4: サニティテストを作成して通過確認**

```typescript
// src/utils/__tests__/sanity.test.ts
describe('sanity', () => {
  it('jest is working', () => {
    expect(1 + 1).toBe(2);
  });
});
```

- [ ] **Step 5: テスト実行**

```bash
npx jest src/utils/__tests__/sanity.test.ts
```

Expected: PASS

- [ ] **Step 6: コミット**

```bash
git add jest.config.js __mocks__/ src/utils/__tests__/sanity.test.ts
git commit -m "feat: add Jest test setup with expo-sqlite mock"
```

---

## Task 3: テーマ定数とディレクトリ構成

**Files:**
- Create: `src/theme.ts`
- Create: ディレクトリ群

- [ ] **Step 1: ディレクトリを作成**

```bash
mkdir -p src/{db/__tests__,store/__tests__,utils/__tests__,screens,components,navigation}
```

- [ ] **Step 2: theme.ts を作成**

```typescript
// src/theme.ts
export const COLORS = {
  bg: '#1a1a2e',
  surface: '#252540',
  surfaceAlt: '#1e1e35',
  accent: '#64b5f6',
  success: '#1a3320',
  successText: '#66bb6a',
  danger: '#3a1a1a',
  dangerText: '#ef5350',
  holiday: '#2a2a1a',
  holidayText: '#888',
  text: '#e0e0e0',
  textMuted: '#888',
  border: '#333',
  white: '#ffffff',
};

export const RADIUS = {
  sm: 6,
  md: 8,
  lg: 12,
  xl: 16,
  full: 999,
};

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
};
```

- [ ] **Step 3: コミット**

```bash
git add src/
git commit -m "feat: add theme constants and directory structure"
```

---

## Task 4: DBスキーマ・初期化

**Files:**
- Create: `src/db/schema.ts`

- [ ] **Step 1: schema.ts を作成**

```typescript
// src/db/schema.ts
import * as SQLite from 'expo-sqlite';

let _db: SQLite.SQLiteDatabase | null = null;

export function getDb(): SQLite.SQLiteDatabase {
  if (!_db) {
    _db = SQLite.openDatabaseSync('timescale.db');
  }
  return _db;
}

export function initDb(): void {
  const db = getDb();
  db.execSync(`
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('quota', 'limit')),
      color TEXT NOT NULL DEFAULT '#64b5f6',
      weekday_budget_min INTEGER NOT NULL DEFAULT 0,
      weekend_budget_min INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      started_at INTEGER NOT NULL,
      ended_at INTEGER,
      duration_sec INTEGER,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
    );
  `);
}

export function resetDbForTesting(): void {
  _db = null;
}
```

- [ ] **Step 2: initDb のテストを作成**

```typescript
// src/db/__tests__/schema.test.ts
import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { initDb } from '../schema';

beforeEach(() => {
  jest.clearAllMocks();
});

it('initDb calls execSync with CREATE TABLE statements', () => {
  initDb();
  expect(mockDbInstance.execSync).toHaveBeenCalledTimes(1);
  const sql = mockDbInstance.execSync.mock.calls[0][0] as string;
  expect(sql).toContain('CREATE TABLE IF NOT EXISTS categories');
  expect(sql).toContain('CREATE TABLE IF NOT EXISTS sessions');
});
```

- [ ] **Step 3: テスト実行**

```bash
npx jest src/db/__tests__/schema.test.ts
```

Expected: PASS

- [ ] **Step 4: コミット**

```bash
git add src/db/schema.ts src/db/__tests__/schema.test.ts
git commit -m "feat: add SQLite schema and initDb"
```

---

## Task 5: clearCheck ユーティリティ (TDD)

**Files:**
- Create: `src/utils/clearCheck.ts`
- Create: `src/utils/__tests__/clearCheck.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/utils/__tests__/clearCheck.test.ts
import { isCategoryCleared, isDayCleared } from '../clearCheck';

describe('isCategoryCleared - quota（ノルマ）', () => {
  it('目標秒数以上でクリア', () => {
    expect(isCategoryCleared('quota', 8 * 60, 8 * 3600)).toBe(true);
  });
  it('目標秒数未満は未クリア', () => {
    expect(isCategoryCleared('quota', 8 * 60, 7 * 3600)).toBe(false);
  });
  it('目標が0分ならば常にクリア', () => {
    expect(isCategoryCleared('quota', 0, 0)).toBe(true);
  });
});

describe('isCategoryCleared - limit（上限）', () => {
  it('上限以内でクリア', () => {
    expect(isCategoryCleared('limit', 2 * 60, 2 * 3600)).toBe(true);
  });
  it('5分未満の超過はクリア', () => {
    expect(isCategoryCleared('limit', 2 * 60, 2 * 3600 + 299)).toBe(true);
  });
  it('ちょうど5分超過はクリア', () => {
    expect(isCategoryCleared('limit', 2 * 60, 2 * 3600 + 300)).toBe(true);
  });
  it('5分超過を超えたら未クリア', () => {
    expect(isCategoryCleared('limit', 2 * 60, 2 * 3600 + 301)).toBe(false);
  });
});

describe('isDayCleared', () => {
  it('全カテゴリクリアで true', () => {
    expect(isDayCleared([true, true, true])).toBe(true);
  });
  it('1つでも未クリアなら false', () => {
    expect(isDayCleared([true, false, true])).toBe(false);
  });
  it('カテゴリなしは false', () => {
    expect(isDayCleared([])).toBe(false);
  });
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/utils/__tests__/clearCheck.test.ts
```

Expected: FAIL（モジュールが存在しない）

- [ ] **Step 3: 実装**

```typescript
// src/utils/clearCheck.ts
export type CategoryType = 'quota' | 'limit';

export function isCategoryCleared(
  type: CategoryType,
  budgetMin: number,
  totalSec: number
): boolean {
  const budgetSec = budgetMin * 60;
  if (type === 'quota') {
    return totalSec >= budgetSec;
  }
  return totalSec <= budgetSec + 300;
}

export function isDayCleared(results: boolean[]): boolean {
  return results.length > 0 && results.every(Boolean);
}
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/utils/__tests__/clearCheck.test.ts
```

Expected: PASS (8/8)

- [ ] **Step 5: コミット**

```bash
git add src/utils/clearCheck.ts src/utils/__tests__/clearCheck.test.ts
git commit -m "feat: add clearCheck utility with TDD"
```

---

## Task 6: dateUtils (TDD)

**Files:**
- Create: `src/utils/dateUtils.ts`
- Create: `src/utils/__tests__/dateUtils.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/utils/__tests__/dateUtils.test.ts
import { getLocalDateString, isWeekend, getBudgetForDate } from '../dateUtils';

describe('getLocalDateString', () => {
  it('Date オブジェクトから YYYY-MM-DD を返す', () => {
    const d = new Date(2026, 4, 20); // May 20, 2026
    expect(getLocalDateString(d)).toBe('2026-05-20');
  });
  it('引数なしで今日の日付を返す', () => {
    const result = getLocalDateString();
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

describe('isWeekend', () => {
  it('日曜は休日', () => {
    expect(isWeekend(new Date(2026, 4, 17))).toBe(true); // Sunday
  });
  it('土曜は休日', () => {
    expect(isWeekend(new Date(2026, 4, 16))).toBe(true); // Saturday
  });
  it('平日は false', () => {
    expect(isWeekend(new Date(2026, 4, 20))).toBe(false); // Wednesday
  });
});

describe('getBudgetForDate', () => {
  const cat = { weekday_budget_min: 480, weekend_budget_min: 0 };
  it('平日は weekday_budget_min を返す', () => {
    expect(getBudgetForDate(cat, new Date(2026, 4, 20))).toBe(480);
  });
  it('休日は weekend_budget_min を返す', () => {
    expect(getBudgetForDate(cat, new Date(2026, 4, 17))).toBe(0);
  });
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/utils/__tests__/dateUtils.test.ts
```

Expected: FAIL

- [ ] **Step 3: 実装**

```typescript
// src/utils/dateUtils.ts
export function getLocalDateString(date: Date = new Date()): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function isWeekend(date: Date = new Date()): boolean {
  const day = date.getDay();
  return day === 0 || day === 6;
}

export function getBudgetForDate(
  category: { weekday_budget_min: number; weekend_budget_min: number },
  date: Date = new Date()
): number {
  return isWeekend(date)
    ? category.weekend_budget_min
    : category.weekday_budget_min;
}

export function formatDuration(totalSec: number): string {
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function formatTime(unixSec: number): string {
  const d = new Date(unixSec * 1000);
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/utils/__tests__/dateUtils.test.ts
```

Expected: PASS (6/6)

- [ ] **Step 5: コミット**

```bash
git add src/utils/dateUtils.ts src/utils/__tests__/dateUtils.test.ts
git commit -m "feat: add dateUtils with TDD"
```

---

## Task 7: categories DB クエリ

**Files:**
- Create: `src/db/categories.ts`
- Create: `src/db/__tests__/categories.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/db/__tests__/categories.test.ts
import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import {
  getAllCategories,
  insertCategory,
  updateCategory,
  deleteCategory,
} from '../categories';

beforeEach(() => jest.clearAllMocks());

const mockCategory = {
  id: 1, name: '仕事', type: 'quota' as const, color: '#ef5350',
  weekday_budget_min: 480, weekend_budget_min: 0, sort_order: 0,
};

it('getAllCategories は getAllSync を呼ぶ', () => {
  mockDbInstance.getAllSync.mockReturnValue([mockCategory]);
  const result = getAllCategories();
  expect(mockDbInstance.getAllSync).toHaveBeenCalledWith(
    expect.stringContaining('SELECT'),
  );
  expect(result).toEqual([mockCategory]);
});

it('insertCategory は runSync を呼んで id を返す', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 42, changes: 1 });
  const id = insertCategory({
    name: '仕事', type: 'quota', color: '#ef5350',
    weekday_budget_min: 480, weekend_budget_min: 0,
  });
  expect(mockDbInstance.runSync).toHaveBeenCalledWith(
    expect.stringContaining('INSERT INTO categories'),
    '仕事', 'quota', '#ef5350', 480, 0,
  );
  expect(id).toBe(42);
});

it('updateCategory は runSync を呼ぶ', () => {
  updateCategory(1, { name: '仕事2' });
  expect(mockDbInstance.runSync).toHaveBeenCalledWith(
    expect.stringContaining('UPDATE categories'),
    '仕事2', 1,
  );
});

it('deleteCategory は runSync を呼ぶ', () => {
  deleteCategory(1);
  expect(mockDbInstance.runSync).toHaveBeenCalledWith(
    expect.stringContaining('DELETE FROM categories'),
    1,
  );
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/db/__tests__/categories.test.ts
```

Expected: FAIL

- [ ] **Step 3: 実装**

```typescript
// src/db/categories.ts
import { getDb } from './schema';

export interface Category {
  id: number;
  name: string;
  type: 'quota' | 'limit';
  color: string;
  weekday_budget_min: number;
  weekend_budget_min: number;
  sort_order: number;
}

export type NewCategory = Omit<Category, 'id' | 'sort_order'>;

export function getAllCategories(): Category[] {
  return getDb().getAllSync<Category>(
    'SELECT * FROM categories ORDER BY sort_order ASC, id ASC',
  );
}

export function insertCategory(c: NewCategory): number {
  const result = getDb().runSync(
    'INSERT INTO categories (name, type, color, weekday_budget_min, weekend_budget_min) VALUES (?, ?, ?, ?, ?)',
    c.name, c.type, c.color, c.weekday_budget_min, c.weekend_budget_min,
  );
  return result.lastInsertRowId;
}

export function updateCategory(id: number, c: Partial<NewCategory>): void {
  const entries = Object.entries(c);
  const fields = entries.map(([k]) => `${k} = ?`).join(', ');
  const values = entries.map(([, v]) => v);
  getDb().runSync(
    `UPDATE categories SET ${fields} WHERE id = ?`,
    ...values, id,
  );
}

export function deleteCategory(id: number): void {
  getDb().runSync('DELETE FROM categories WHERE id = ?', id);
}
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/db/__tests__/categories.test.ts
```

Expected: PASS (4/4)

- [ ] **Step 5: コミット**

```bash
git add src/db/categories.ts src/db/__tests__/categories.test.ts
git commit -m "feat: add categories DB queries with TDD"
```

---

## Task 8: sessions DB クエリ

**Files:**
- Create: `src/db/sessions.ts`
- Create: `src/db/__tests__/sessions.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/db/__tests__/sessions.test.ts
import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import {
  startSession, stopSession, getSessionsForDate,
  getTotalSecByCategory, getInProgressSession,
} from '../sessions';

beforeEach(() => jest.clearAllMocks());

it('startSession は INSERT して id を返す', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 5, changes: 1 });
  const id = startSession(1, '2026-05-20');
  expect(mockDbInstance.runSync).toHaveBeenCalledWith(
    expect.stringContaining('INSERT INTO sessions'),
    1, '2026-05-20', expect.any(Number),
  );
  expect(id).toBe(5);
});

it('stopSession は ended_at と duration_sec を UPDATE する', () => {
  stopSession(5);
  expect(mockDbInstance.runSync).toHaveBeenCalledWith(
    expect.stringContaining('UPDATE sessions'),
    expect.any(Number), 5,
  );
});

it('getSessionsForDate は date でフィルタする', () => {
  mockDbInstance.getAllSync.mockReturnValue([]);
  getSessionsForDate('2026-05-20');
  expect(mockDbInstance.getAllSync).toHaveBeenCalledWith(
    expect.stringContaining('WHERE date = ?'),
    '2026-05-20',
  );
});

it('getTotalSecByCategory は category_id でグループ化する', () => {
  mockDbInstance.getAllSync.mockReturnValue([
    { category_id: 1, total: 3600 },
    { category_id: 2, total: 7200 },
  ]);
  const result = getTotalSecByCategory('2026-05-20');
  expect(result).toEqual({ 1: 3600, 2: 7200 });
});

it('getInProgressSession は ended_at IS NULL で検索する', () => {
  mockDbInstance.getFirstSync.mockReturnValue(null);
  const result = getInProgressSession();
  expect(mockDbInstance.getFirstSync).toHaveBeenCalledWith(
    expect.stringContaining('ended_at IS NULL'),
  );
  expect(result).toBeNull();
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/db/__tests__/sessions.test.ts
```

Expected: FAIL

- [ ] **Step 3: 実装**

```typescript
// src/db/sessions.ts
import { getDb } from './schema';

export interface Session {
  id: number;
  category_id: number;
  date: string;
  started_at: number;
  ended_at: number | null;
  duration_sec: number | null;
}

export function startSession(categoryId: number, date: string): number {
  const startedAt = Math.floor(Date.now() / 1000);
  const result = getDb().runSync(
    'INSERT INTO sessions (category_id, date, started_at) VALUES (?, ?, ?)',
    categoryId, date, startedAt,
  );
  return result.lastInsertRowId;
}

export function stopSession(sessionId: number): void {
  const endedAt = Math.floor(Date.now() / 1000);
  getDb().runSync(
    'UPDATE sessions SET ended_at = ?, duration_sec = ended_at - started_at WHERE id = ?',
    endedAt, sessionId,
  );
}

export function getSessionsForDate(date: string): Session[] {
  return getDb().getAllSync<Session>(
    'SELECT * FROM sessions WHERE date = ? ORDER BY started_at ASC',
    date,
  );
}

export function getTotalSecByCategory(date: string): Record<number, number> {
  const rows = getDb().getAllSync<{ category_id: number; total: number }>(
    `SELECT category_id,
     SUM(CASE WHEN ended_at IS NOT NULL THEN duration_sec
              ELSE CAST(strftime('%s','now') AS INTEGER) - started_at END) AS total
     FROM sessions WHERE date = ? GROUP BY category_id`,
    date,
  );
  return Object.fromEntries(rows.map(r => [r.category_id, r.total ?? 0]));
}

export function getInProgressSession(): Session | null {
  return getDb().getFirstSync<Session>(
    'SELECT * FROM sessions WHERE ended_at IS NULL LIMIT 1',
  );
}
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/db/__tests__/sessions.test.ts
```

Expected: PASS (5/5)

- [ ] **Step 5: コミット**

```bash
git add src/db/sessions.ts src/db/__tests__/sessions.test.ts
git commit -m "feat: add sessions DB queries with TDD"
```

---

## Task 9: categoryStore (Zustand)

**Files:**
- Create: `src/store/categoryStore.ts`
- Create: `src/store/__tests__/categoryStore.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/store/__tests__/categoryStore.test.ts
import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { useCategoryStore } from '../categoryStore';

const mockCategory = {
  id: 1, name: '仕事', type: 'quota' as const, color: '#ef5350',
  weekday_budget_min: 480, weekend_budget_min: 0, sort_order: 0,
};

beforeEach(() => {
  jest.clearAllMocks();
  useCategoryStore.setState({ categories: [] });
});

it('loadCategories でカテゴリを読み込む', () => {
  mockDbInstance.getAllSync.mockReturnValue([mockCategory]);
  useCategoryStore.getState().loadCategories();
  expect(useCategoryStore.getState().categories).toEqual([mockCategory]);
});

it('addCategory でカテゴリを追加して再読み込む', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 1, changes: 1 });
  mockDbInstance.getAllSync.mockReturnValue([mockCategory]);
  useCategoryStore.getState().addCategory({
    name: '仕事', type: 'quota', color: '#ef5350',
    weekday_budget_min: 480, weekend_budget_min: 0,
  });
  expect(useCategoryStore.getState().categories).toEqual([mockCategory]);
});

it('removeCategory でカテゴリを削除して再読み込む', () => {
  mockDbInstance.getAllSync.mockReturnValue([]);
  useCategoryStore.getState().removeCategory(1);
  expect(useCategoryStore.getState().categories).toEqual([]);
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/store/__tests__/categoryStore.test.ts
```

Expected: FAIL

- [ ] **Step 3: 実装**

```typescript
// src/store/categoryStore.ts
import { create } from 'zustand';
import {
  Category, NewCategory,
  getAllCategories, insertCategory,
  updateCategory as dbUpdateCategory,
  deleteCategory as dbDeleteCategory,
} from '../db/categories';

interface CategoryState {
  categories: Category[];
  loadCategories: () => void;
  addCategory: (c: NewCategory) => void;
  editCategory: (id: number, c: Partial<NewCategory>) => void;
  removeCategory: (id: number) => void;
}

export const useCategoryStore = create<CategoryState>((set) => ({
  categories: [],
  loadCategories: () => set({ categories: getAllCategories() }),
  addCategory: (c) => { insertCategory(c); set({ categories: getAllCategories() }); },
  editCategory: (id, c) => { dbUpdateCategory(id, c); set({ categories: getAllCategories() }); },
  removeCategory: (id) => { dbDeleteCategory(id); set({ categories: getAllCategories() }); },
}));
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/store/__tests__/categoryStore.test.ts
```

Expected: PASS (3/3)

- [ ] **Step 5: コミット**

```bash
git add src/store/categoryStore.ts src/store/__tests__/categoryStore.test.ts
git commit -m "feat: add categoryStore Zustand store with TDD"
```

---

## Task 10: timerStore (Zustand)

**Files:**
- Create: `src/store/timerStore.ts`
- Create: `src/store/__tests__/timerStore.test.ts`

- [ ] **Step 1: テストを先に書く**

```typescript
// src/store/__tests__/timerStore.test.ts
import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { useTimerStore } from '../timerStore';

beforeEach(() => {
  jest.clearAllMocks();
  useTimerStore.setState({
    activeSessionId: null, activeCategoryId: null, startedAt: null,
  });
});

it('初期状態はタイマー停止', () => {
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBeNull();
  expect(s.activeCategoryId).toBeNull();
});

it('startTimer でセッションIDとカテゴリIDが設定される', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 7, changes: 1 });
  useTimerStore.getState().startTimer(1);
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBe(7);
  expect(s.activeCategoryId).toBe(1);
  expect(s.startedAt).not.toBeNull();
});

it('startTimer を2回呼んでも2重起動しない', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 7, changes: 1 });
  useTimerStore.getState().startTimer(1);
  useTimerStore.getState().startTimer(2);
  expect(mockDbInstance.runSync).toHaveBeenCalledTimes(1);
  expect(useTimerStore.getState().activeCategoryId).toBe(1);
});

it('stopTimer でセッションが停止してnullに戻る', () => {
  useTimerStore.setState({ activeSessionId: 7, activeCategoryId: 1, startedAt: 0 });
  useTimerStore.getState().stopTimer();
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBeNull();
  expect(s.activeCategoryId).toBeNull();
});

it('restoreTimer: 進行中セッションがあればストアに反映する', () => {
  mockDbInstance.getFirstSync.mockReturnValue({
    id: 3, category_id: 2, date: '2026-05-20',
    started_at: 1000000, ended_at: null, duration_sec: null,
  });
  useTimerStore.getState().restoreTimer();
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBe(3);
  expect(s.activeCategoryId).toBe(2);
});
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
npx jest src/store/__tests__/timerStore.test.ts
```

Expected: FAIL

- [ ] **Step 3: 実装**

```typescript
// src/store/timerStore.ts
import { create } from 'zustand';
import { startSession, stopSession, getInProgressSession } from '../db/sessions';
import { getLocalDateString } from '../utils/dateUtils';

interface TimerState {
  activeSessionId: number | null;
  activeCategoryId: number | null;
  startedAt: number | null;
  startTimer: (categoryId: number) => void;
  stopTimer: () => void;
  restoreTimer: () => void;
}

export const useTimerStore = create<TimerState>((set, get) => ({
  activeSessionId: null,
  activeCategoryId: null,
  startedAt: null,

  startTimer: (categoryId) => {
    if (get().activeSessionId !== null) return;
    const date = getLocalDateString();
    const sessionId = startSession(categoryId, date);
    set({ activeSessionId: sessionId, activeCategoryId: categoryId, startedAt: Math.floor(Date.now() / 1000) });
  },

  stopTimer: () => {
    const { activeSessionId } = get();
    if (activeSessionId === null) return;
    stopSession(activeSessionId);
    set({ activeSessionId: null, activeCategoryId: null, startedAt: null });
  },

  restoreTimer: () => {
    const session = getInProgressSession();
    if (session) {
      set({ activeSessionId: session.id, activeCategoryId: session.category_id, startedAt: session.started_at });
    }
  },
}));
```

- [ ] **Step 4: テスト実行**

```bash
npx jest src/store/__tests__/timerStore.test.ts
```

Expected: PASS (5/5)

- [ ] **Step 5: コミット**

```bash
git add src/store/timerStore.ts src/store/__tests__/timerStore.test.ts
git commit -m "feat: add timerStore Zustand store with TDD"
```

---

## Task 11: ナビゲーションシェルと App.tsx

**Files:**
- Create: `src/navigation/AppNavigator.tsx`
- Create: `src/screens/TodayScreen.tsx` (プレースホルダー)
- Create: `src/screens/CalendarScreen.tsx` (プレースホルダー)
- Create: `src/screens/DayDetailScreen.tsx` (プレースホルダー)
- Create: `src/screens/SettingsScreen.tsx` (プレースホルダー)
- Create: `src/screens/CategoryEditScreen.tsx` (プレースホルダー)
- Modify: `App.tsx`

- [ ] **Step 1: プレースホルダー画面を作成**

各ファイルに同じパターンで作成する（TodayScreen の例、他も同様）：

```typescript
// src/screens/TodayScreen.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS } from '../theme';

export default function TodayScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>今日</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bg, alignItems: 'center', justifyContent: 'center' },
  text: { color: COLORS.text, fontSize: 18 },
});
```

同様に `CalendarScreen.tsx`（テキスト「カレンダー」）、`DayDetailScreen.tsx`（テキスト「日付詳細」）、`SettingsScreen.tsx`（テキスト「設定」）、`CategoryEditScreen.tsx`（テキスト「カテゴリ編集」）を作成。

- [ ] **Step 2: ナビゲーターを作成**

```typescript
// src/navigation/AppNavigator.tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Text } from 'react-native';
import { COLORS } from '../theme';
import TodayScreen from '../screens/TodayScreen';
import CalendarScreen from '../screens/CalendarScreen';
import DayDetailScreen from '../screens/DayDetailScreen';
import SettingsScreen from '../screens/SettingsScreen';
import CategoryEditScreen from '../screens/CategoryEditScreen';

export type CalendarStackParamList = {
  CalendarHome: undefined;
  DayDetail: { date: string };
};

export type SettingsStackParamList = {
  SettingsHome: undefined;
  CategoryEdit: { categoryId?: number };
};

const Tab = createBottomTabNavigator();
const CalendarStack = createNativeStackNavigator<CalendarStackParamList>();
const SettingsStack = createNativeStackNavigator<SettingsStackParamList>();

function CalendarNavigator() {
  return (
    <CalendarStack.Navigator screenOptions={{ headerStyle: { backgroundColor: COLORS.bg }, headerTintColor: COLORS.text }}>
      <CalendarStack.Screen name="CalendarHome" component={CalendarScreen} options={{ title: 'カレンダー' }} />
      <CalendarStack.Screen name="DayDetail" component={DayDetailScreen} options={{ title: '詳細' }} />
    </CalendarStack.Navigator>
  );
}

function SettingsNavigator() {
  return (
    <SettingsStack.Navigator screenOptions={{ headerStyle: { backgroundColor: COLORS.bg }, headerTintColor: COLORS.text }}>
      <SettingsStack.Screen name="SettingsHome" component={SettingsScreen} options={{ title: '設定' }} />
      <SettingsStack.Screen name="CategoryEdit" component={CategoryEditScreen} options={{ title: 'カテゴリ編集' }} />
    </SettingsStack.Navigator>
  );
}

export default function AppNavigator() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={{
          tabBarStyle: { backgroundColor: COLORS.surface, borderTopColor: COLORS.border },
          tabBarActiveTintColor: COLORS.accent,
          tabBarInactiveTintColor: COLORS.textMuted,
          headerStyle: { backgroundColor: COLORS.bg },
          headerTintColor: COLORS.text,
        }}
      >
        <Tab.Screen
          name="今日"
          component={TodayScreen}
          options={{ tabBarIcon: ({ color }) => <Text style={{ color }}>⏱</Text> }}
        />
        <Tab.Screen
          name="カレンダー"
          component={CalendarNavigator}
          options={{ headerShown: false, tabBarIcon: ({ color }) => <Text style={{ color }}>📅</Text> }}
        />
        <Tab.Screen
          name="設定"
          component={SettingsNavigator}
          options={{ headerShown: false, tabBarIcon: ({ color }) => <Text style={{ color }}>⚙️</Text> }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
```

- [ ] **Step 3: App.tsx を更新**

```typescript
// App.tsx
import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import AppNavigator from './src/navigation/AppNavigator';
import { initDb } from './src/db/schema';
import { useCategoryStore } from './src/store/categoryStore';
import { useTimerStore } from './src/store/timerStore';

export default function App() {
  useEffect(() => {
    initDb();
    useCategoryStore.getState().loadCategories();
    useTimerStore.getState().restoreTimer();
  }, []);

  return (
    <>
      <StatusBar style="light" />
      <AppNavigator />
    </>
  );
}
```

- [ ] **Step 4: 動作確認**

```bash
npx expo start
```

Expected: アプリが起動し、3タブ（今日・カレンダー・設定）が表示される。各タブをタップして画面が切り替わること。

- [ ] **Step 5: コミット**

```bash
git add src/ App.tsx
git commit -m "feat: add navigation shell with placeholder screens"
```

---

## Task 12: ProgressBar コンポーネント

**Files:**
- Create: `src/components/ProgressBar.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/components/ProgressBar.tsx
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { COLORS, RADIUS } from '../theme';

interface Props {
  progress: number; // 0.0 – 1.0
  color: string;
  overLimit?: boolean;
}

export default function ProgressBar({ progress, color, overLimit = false }: Props) {
  const clampedWidth = Math.min(Math.max(progress, 0), 1) * 100;
  return (
    <View style={styles.track}>
      <View
        style={[
          styles.fill,
          { width: `${clampedWidth}%`, backgroundColor: overLimit ? COLORS.dangerText : color },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  track: {
    height: 6,
    backgroundColor: COLORS.border,
    borderRadius: RADIUS.full,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    borderRadius: RADIUS.full,
  },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/components/ProgressBar.tsx
git commit -m "feat: add ProgressBar component"
```

---

## Task 13: CategoryCard コンポーネント

**Files:**
- Create: `src/components/CategoryCard.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/components/CategoryCard.tsx
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Category } from '../db/categories';
import { isCategoryCleared } from '../utils/clearCheck';
import { formatDuration } from '../utils/dateUtils';
import ProgressBar from './ProgressBar';
import { COLORS, RADIUS, SPACING } from '../theme';

interface Props {
  category: Category;
  totalSec: number;
  budgetMin: number;
  isActive: boolean;
  onPress: () => void;
}

export default function CategoryCard({ category, totalSec, budgetMin, isActive, onPress }: Props) {
  const budgetSec = budgetMin * 60;
  const cleared = isCategoryCleared(category.type, budgetMin, totalSec);
  const progress = budgetSec > 0 ? totalSec / budgetSec : 0;
  const overLimit = category.type === 'limit' && totalSec > budgetSec + 300;

  const displayTime =
    category.type === 'quota'
      ? `${formatDuration(totalSec)} / ${formatDuration(budgetSec)}`
      : `残り ${formatDuration(Math.max(0, budgetSec - totalSec))}`;

  return (
    <TouchableOpacity style={[styles.card, isActive && styles.cardActive]} onPress={onPress} activeOpacity={0.8}>
      <View style={styles.header}>
        <View style={styles.left}>
          <View style={[styles.dot, { backgroundColor: category.color }]} />
          <Text style={styles.name}>{category.name}</Text>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{category.type === 'quota' ? 'ノルマ' : '上限'}</Text>
          </View>
          {cleared && <Text style={styles.check}>✓</Text>}
        </View>
        <Text style={[styles.time, overLimit && styles.timeOver]}>{displayTime}</Text>
      </View>
      <ProgressBar progress={progress} color={category.color} overLimit={overLimit} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  cardActive: {
    borderWidth: 1,
    borderColor: COLORS.accent,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.sm,
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 10, height: 10, borderRadius: RADIUS.full },
  name: { color: COLORS.text, fontSize: 14, fontWeight: 'bold' },
  badge: {
    backgroundColor: COLORS.surfaceAlt,
    borderRadius: RADIUS.sm,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
  badgeText: { color: COLORS.textMuted, fontSize: 10 },
  check: { color: COLORS.successText, fontSize: 14 },
  time: { color: COLORS.text, fontSize: 12, fontFamily: 'monospace' },
  timeOver: { color: COLORS.dangerText },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/components/CategoryCard.tsx
git commit -m "feat: add CategoryCard component"
```

---

## Task 14: TimerBanner コンポーネント

**Files:**
- Create: `src/components/TimerBanner.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/components/TimerBanner.tsx
import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, RADIUS, SPACING } from '../theme';
import { formatDuration } from '../utils/dateUtils';

interface Props {
  categoryName: string;
  startedAt: number;
  onStop: () => void;
}

export default function TimerBanner({ categoryName, startedAt, onStop }: Props) {
  const [elapsed, setElapsed] = useState(Math.floor(Date.now() / 1000) - startedAt);

  useEffect(() => {
    const interval = setInterval(() => {
      setElapsed(Math.floor(Date.now() / 1000) - startedAt);
    }, 1000);
    return () => clearInterval(interval);
  }, [startedAt]);

  return (
    <View style={styles.banner}>
      <View>
        <Text style={styles.label}>計測中</Text>
        <Text style={styles.name}>{categoryName}</Text>
      </View>
      <Text style={styles.timer}>{formatDuration(elapsed)}</Text>
      <TouchableOpacity style={styles.stopBtn} onPress={onStop}>
        <Text style={styles.stopText}>STOP</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: '#1e3a5f',
    borderRadius: RADIUS.lg,
    padding: SPACING.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: SPACING.md,
  },
  label: { color: COLORS.accent, fontSize: 10, fontWeight: 'bold' },
  name: { color: COLORS.text, fontSize: 13 },
  timer: { color: COLORS.accent, fontSize: 22, fontWeight: 'bold', fontFamily: 'monospace' },
  stopBtn: {
    backgroundColor: COLORS.dangerText,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  stopText: { color: COLORS.white, fontSize: 12, fontWeight: 'bold' },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/components/TimerBanner.tsx
git commit -m "feat: add TimerBanner component with live elapsed timer"
```

---

## Task 15: TodayScreen 実装

**Files:**
- Modify: `src/screens/TodayScreen.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/screens/TodayScreen.tsx
import React, { useEffect, useState, useCallback } from 'react';
import { View, FlatList, Text, StyleSheet, SafeAreaView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useCategoryStore } from '../store/categoryStore';
import { useTimerStore } from '../store/timerStore';
import { getTotalSecByCategory } from '../db/sessions';
import { getBudgetForDate, getLocalDateString } from '../utils/dateUtils';
import { COLORS, SPACING } from '../theme';
import CategoryCard from '../components/CategoryCard';
import TimerBanner from '../components/TimerBanner';

export default function TodayScreen() {
  const categories = useCategoryStore(s => s.categories);
  const { activeSessionId, activeCategoryId, startedAt, startTimer, stopTimer } = useTimerStore();
  const [totalByCategory, setTotalByCategory] = useState<Record<number, number>>({});
  const today = getLocalDateString();

  const refresh = useCallback(() => {
    setTotalByCategory(getTotalSecByCategory(today));
  }, [today]);

  useFocusEffect(useCallback(() => {
    refresh();
    const interval = setInterval(refresh, 5000);
    return () => clearInterval(interval);
  }, [refresh]));

  const handlePress = (categoryId: number) => {
    if (activeCategoryId === categoryId) {
      stopTimer();
    } else if (activeSessionId === null) {
      startTimer(categoryId);
    }
    setTimeout(refresh, 200);
  };

  const activeCategory = categories.find(c => c.id === activeCategoryId);
  const now = new Date();

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <Text style={styles.dateText}>{today}（{['日', '月', '火', '水', '木', '金', '土'][now.getDay()]}）</Text>

        {activeCategory && startedAt && (
          <TimerBanner
            categoryName={activeCategory.name}
            startedAt={startedAt}
            onStop={() => { stopTimer(); setTimeout(refresh, 200); }}
          />
        )}

        <FlatList
          data={categories}
          keyExtractor={item => String(item.id)}
          renderItem={({ item }) => (
            <CategoryCard
              category={item}
              totalSec={totalByCategory[item.id] ?? 0}
              budgetMin={getBudgetForDate(item, now)}
              isActive={item.id === activeCategoryId}
              onPress={() => handlePress(item.id)}
            />
          )}
          ListEmptyComponent={
            <Text style={styles.empty}>設定画面からカテゴリを追加してください</Text>
          }
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  dateText: { color: COLORS.textMuted, fontSize: 13, textAlign: 'center', marginBottom: SPACING.md },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40 },
});
```

- [ ] **Step 2: 動作確認**

```bash
npx expo start
```

Expected: 今日タブにカテゴリカードが表示される（設定でカテゴリを追加してから確認）。

- [ ] **Step 3: コミット**

```bash
git add src/screens/TodayScreen.tsx
git commit -m "feat: implement TodayScreen with category cards and timer"
```

---

## Task 16: CalendarGrid コンポーネント

**Files:**
- Create: `src/components/CalendarGrid.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/components/CalendarGrid.tsx
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { COLORS, RADIUS, SPACING } from '../theme';

export type DayStatus = 'cleared' | 'failed' | 'holiday' | 'future' | 'today';

interface Props {
  year: number;
  month: number; // 0-indexed
  statusMap: Record<string, DayStatus>; // key: 'YYYY-MM-DD'
  today: string;
  onDayPress: (date: string) => void;
}

const DAY_LABELS = ['日', '月', '火', '水', '木', '金', '土'];

const STATUS_STYLES: Record<DayStatus, { bg: string; text: string; bold?: boolean }> = {
  cleared:  { bg: COLORS.success,  text: COLORS.successText, bold: true },
  failed:   { bg: COLORS.danger,   text: COLORS.dangerText },
  holiday:  { bg: COLORS.holiday,  text: COLORS.holidayText },
  future:   { bg: 'transparent',   text: COLORS.textMuted },
  today:    { bg: 'transparent',   text: COLORS.accent, bold: true },
};

export default function CalendarGrid({ year, month, statusMap, today, onDayPress }: Props) {
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ];

  const getDate = (day: number) => {
    const m = String(month + 1).padStart(2, '0');
    const d = String(day).padStart(2, '0');
    return `${year}-${m}-${d}`;
  };

  const getStatus = (day: number): DayStatus => {
    const dateStr = getDate(day);
    if (dateStr === today) return 'today';
    if (dateStr > today) return 'future';
    return statusMap[dateStr] ?? 'future';
  };

  return (
    <View>
      <View style={styles.dayLabels}>
        {DAY_LABELS.map(l => (
          <Text key={l} style={[styles.dayLabel, (l === '日') && { color: COLORS.dangerText }, (l === '土') && { color: COLORS.accent }]}>{l}</Text>
        ))}
      </View>
      <View style={styles.grid}>
        {cells.map((day, i) => {
          if (!day) return <View key={`empty-${i}`} style={styles.cell} />;
          const status = getStatus(day);
          const s = STATUS_STYLES[status];
          const isToday = status === 'today';
          return (
            <TouchableOpacity
              key={day}
              style={[styles.cell, { backgroundColor: s.bg }, isToday && styles.todayBorder]}
              onPress={() => day && getDate(day) <= today && onDayPress(getDate(day))}
              activeOpacity={0.7}
            >
              <Text style={[styles.dayNum, { color: s.text }, s.bold && { fontWeight: 'bold' }]}>
                {day}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  dayLabels: { flexDirection: 'row', marginBottom: SPACING.xs },
  dayLabel: { flex: 1, textAlign: 'center', color: COLORS.textMuted, fontSize: 10 },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  cell: {
    width: `${100 / 7}%`,
    aspectRatio: 1,
    borderRadius: RADIUS.md,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 2,
  },
  todayBorder: { borderWidth: 2, borderColor: COLORS.accent },
  dayNum: { fontSize: 12 },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/components/CalendarGrid.tsx
git commit -m "feat: add CalendarGrid component"
```

---

## Task 17: CalendarScreen 実装

**Files:**
- Modify: `src/screens/CalendarScreen.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/screens/CalendarScreen.tsx
import React, { useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { CalendarStackParamList } from '../navigation/AppNavigator';
import { useCategoryStore } from '../store/categoryStore';
import { getTotalSecByCategory } from '../db/sessions';
import { isCategoryCleared, isDayCleared } from '../utils/clearCheck';
import { getBudgetForDate, getLocalDateString, isWeekend } from '../utils/dateUtils';
import CalendarGrid, { DayStatus } from '../components/CalendarGrid';
import { COLORS, SPACING } from '../theme';

type Props = NativeStackScreenProps<CalendarStackParamList, 'CalendarHome'>;

export default function CalendarScreen({ navigation }: Props) {
  const today = getLocalDateString();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth());
  const [statusMap, setStatusMap] = useState<Record<string, DayStatus>>({});
  const categories = useCategoryStore(s => s.categories);

  const buildStatusMap = useCallback(() => {
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const map: Record<string, DayStatus> = {};

    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, month, d);
      const dateStr = getLocalDateString(date);
      if (dateStr >= today) continue;

      if (isWeekend(date)) {
        const totalMap = getTotalSecByCategory(dateStr);
        const weekend = categories.filter(c => c.weekend_budget_min > 0);
        if (weekend.length === 0) { map[dateStr] = 'holiday'; continue; }
        const results = weekend.map(c =>
          isCategoryCleared(c.type, c.weekend_budget_min, totalMap[c.id] ?? 0)
        );
        map[dateStr] = isDayCleared(results) ? 'cleared' : 'failed';
      } else {
        const totalMap = getTotalSecByCategory(dateStr);
        const results = categories.map(c =>
          isCategoryCleared(c.type, getBudgetForDate(c, date), totalMap[c.id] ?? 0)
        );
        map[dateStr] = isDayCleared(results) ? 'cleared' : 'failed';
      }
    }
    setStatusMap(map);
  }, [year, month, today, categories]);

  useFocusEffect(useCallback(() => { buildStatusMap(); }, [buildStatusMap]));

  const changeMonth = (delta: number) => {
    const d = new Date(year, month + delta, 1);
    setYear(d.getFullYear());
    setMonth(d.getMonth());
  };

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => changeMonth(-1)}><Text style={styles.arrow}>‹</Text></TouchableOpacity>
          <Text style={styles.title}>{year}年 {month + 1}月</Text>
          <TouchableOpacity onPress={() => changeMonth(1)}><Text style={styles.arrow}>›</Text></TouchableOpacity>
        </View>
        <CalendarGrid
          year={year}
          month={month}
          statusMap={statusMap}
          today={today}
          onDayPress={(date) => navigation.navigate('DayDetail', { date })}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: SPACING.lg },
  title: { color: COLORS.text, fontSize: 16, fontWeight: 'bold' },
  arrow: { color: COLORS.textMuted, fontSize: 24, paddingHorizontal: SPACING.md },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/screens/CalendarScreen.tsx
git commit -m "feat: implement CalendarScreen with day status"
```

---

## Task 18: DayDetailScreen 実装

**Files:**
- Modify: `src/screens/DayDetailScreen.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/screens/DayDetailScreen.tsx
import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, StyleSheet, SafeAreaView } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { CalendarStackParamList } from '../navigation/AppNavigator';
import { useCategoryStore } from '../store/categoryStore';
import { getSessionsForDate, getTotalSecByCategory, Session } from '../db/sessions';
import { isCategoryCleared, isDayCleared } from '../utils/clearCheck';
import { getBudgetForDate, formatDuration, formatTime } from '../utils/dateUtils';
import { COLORS, RADIUS, SPACING } from '../theme';

type Props = NativeStackScreenProps<CalendarStackParamList, 'DayDetail'>;

export default function DayDetailScreen({ route }: Props) {
  const { date } = route.params;
  const categories = useCategoryStore(s => s.categories);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [totalMap, setTotalMap] = useState<Record<number, number>>({});

  useEffect(() => {
    setSessions(getSessionsForDate(date));
    setTotalMap(getTotalSecByCategory(date));
  }, [date]);

  const dateObj = new Date(date + 'T00:00:00');
  const categoryResults = categories.map(c => ({
    category: c,
    budget: getBudgetForDate(c, dateObj),
    total: totalMap[c.id] ?? 0,
    sessions: sessions.filter(s => s.category_id === c.id),
    cleared: isCategoryCleared(c.type, getBudgetForDate(c, dateObj), totalMap[c.id] ?? 0),
  }));
  const dayCleared = isDayCleared(categoryResults.map(r => r.cleared));

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.container}>
        <View style={styles.titleRow}>
          <Text style={styles.dateText}>{date}</Text>
          <View style={[styles.badge, { backgroundColor: dayCleared ? COLORS.success : COLORS.danger }]}>
            <Text style={[styles.badgeText, { color: dayCleared ? COLORS.successText : COLORS.dangerText }]}>
              {dayCleared ? '✓ クリア' : '✗ 未クリア'}
            </Text>
          </View>
        </View>

        {categoryResults.map(({ category, budget, total, sessions: cats, cleared }) => (
          <View key={category.id} style={styles.card}>
            <View style={styles.cardHeader}>
              <View style={styles.left}>
                <View style={[styles.dot, { backgroundColor: category.color }]} />
                <Text style={styles.catName}>{category.name}</Text>
                <Text style={styles.badgeType}>{category.type === 'quota' ? 'ノルマ' : '上限'}</Text>
              </View>
              <View style={styles.right}>
                <Text style={styles.timeText}>
                  {formatDuration(total)} / {formatDuration(budget * 60)}
                </Text>
                {cleared && <Text style={styles.check}>✓</Text>}
              </View>
            </View>
            {cats.length > 0 && (
              <View style={styles.sessionList}>
                {cats.map(s => (
                  <View key={s.id} style={styles.sessionRow}>
                    <Text style={styles.sessionTime}>
                      {formatTime(s.started_at)}–{s.ended_at ? formatTime(s.ended_at) : '計測中'}
                    </Text>
                    <Text style={styles.sessionDuration}>
                      ({formatDuration(s.duration_sec ?? 0)})
                    </Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  titleRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: SPACING.lg },
  dateText: { color: COLORS.text, fontSize: 16, fontWeight: 'bold' },
  badge: { borderRadius: RADIUS.full, paddingHorizontal: SPACING.sm, paddingVertical: 2 },
  badgeText: { fontSize: 12 },
  card: { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: SPACING.md, marginBottom: SPACING.sm },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.sm },
  left: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  right: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  dot: { width: 8, height: 8, borderRadius: RADIUS.full },
  catName: { color: COLORS.text, fontSize: 13, fontWeight: 'bold' },
  badgeType: { color: COLORS.textMuted, fontSize: 10, backgroundColor: COLORS.surfaceAlt, borderRadius: 4, paddingHorizontal: 5 },
  timeText: { color: COLORS.text, fontSize: 12, fontFamily: 'monospace' },
  check: { color: COLORS.successText, fontSize: 14 },
  sessionList: { borderTopWidth: 1, borderTopColor: COLORS.border, paddingTop: SPACING.sm, gap: 4 },
  sessionRow: { flexDirection: 'row', justifyContent: 'space-between' },
  sessionTime: { color: COLORS.textMuted, fontSize: 11 },
  sessionDuration: { color: COLORS.textMuted, fontSize: 11 },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/screens/DayDetailScreen.tsx
git commit -m "feat: implement DayDetailScreen"
```

---

## Task 19: SettingsScreen 実装

**Files:**
- Modify: `src/screens/SettingsScreen.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/screens/SettingsScreen.tsx
import React from 'react';
import { View, Text, FlatList, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { SettingsStackParamList } from '../navigation/AppNavigator';
import { useCategoryStore } from '../store/categoryStore';
import { formatDuration } from '../utils/dateUtils';
import { COLORS, RADIUS, SPACING } from '../theme';

type Props = NativeStackScreenProps<SettingsStackParamList, 'SettingsHome'>;

export default function SettingsScreen({ navigation }: Props) {
  const categories = useCategoryStore(s => s.categories);

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.container}>
        <FlatList
          data={categories}
          keyExtractor={item => String(item.id)}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.card}
              onPress={() => navigation.navigate('CategoryEdit', { categoryId: item.id })}
              activeOpacity={0.8}
            >
              <View style={styles.left}>
                <View style={[styles.dot, { backgroundColor: item.color }]} />
                <View>
                  <Text style={styles.name}>{item.name}</Text>
                  <Text style={styles.sub}>
                    {item.type === 'quota' ? 'ノルマ' : '上限'} ·{' '}
                    平日 {formatDuration(item.weekday_budget_min * 60)} /{' '}
                    休日 {formatDuration(item.weekend_budget_min * 60)}
                  </Text>
                </View>
              </View>
              <Text style={styles.arrow}>›</Text>
            </TouchableOpacity>
          )}
          ListEmptyComponent={<Text style={styles.empty}>カテゴリがまだありません</Text>}
        />

        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => navigation.navigate('CategoryEdit', {})}
          activeOpacity={0.8}
        >
          <Text style={styles.addText}>＋ カテゴリを追加</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  card: {
    backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: SPACING.md,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: SPACING.sm,
  },
  left: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm },
  dot: { width: 12, height: 12, borderRadius: RADIUS.full },
  name: { color: COLORS.text, fontSize: 14, fontWeight: 'bold' },
  sub: { color: COLORS.textMuted, fontSize: 11, marginTop: 2 },
  arrow: { color: COLORS.textMuted, fontSize: 18 },
  empty: { color: COLORS.textMuted, textAlign: 'center', marginTop: 40 },
  addBtn: {
    borderWidth: 1, borderColor: COLORS.border, borderStyle: 'dashed',
    borderRadius: RADIUS.lg, padding: SPACING.md, alignItems: 'center',
    marginTop: SPACING.sm,
  },
  addText: { color: COLORS.accent, fontSize: 14 },
});
```

- [ ] **Step 2: コミット**

```bash
git add src/screens/SettingsScreen.tsx
git commit -m "feat: implement SettingsScreen with category list"
```

---

## Task 20: CategoryEditScreen 実装

**Files:**
- Modify: `src/screens/CategoryEditScreen.tsx`

- [ ] **Step 1: 実装**

```typescript
// src/screens/CategoryEditScreen.tsx
import React, { useState, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, ScrollView,
  StyleSheet, Alert, SafeAreaView,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { SettingsStackParamList } from '../navigation/AppNavigator';
import { useCategoryStore } from '../store/categoryStore';
import { COLORS, RADIUS, SPACING } from '../theme';
import { CategoryType } from '../utils/clearCheck';

type Props = NativeStackScreenProps<SettingsStackParamList, 'CategoryEdit'>;

const COLOR_OPTIONS = ['#ef5350', '#66bb6a', '#ab47bc', '#42a5f5', '#ffca28', '#ff7043', '#26c6da', '#ec407a'];

function TimeInput({ label, minutes, onChange }: { label: string; minutes: number; onChange: (m: number) => void }) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.timeRow}>
        <TextInput
          style={styles.timeInput}
          keyboardType="number-pad"
          value={String(h)}
          onChangeText={v => onChange(Math.max(0, parseInt(v) || 0) * 60 + m)}
          maxLength={2}
        />
        <Text style={styles.timeSep}>時間</Text>
        <TextInput
          style={styles.timeInput}
          keyboardType="number-pad"
          value={String(m)}
          onChangeText={v => onChange(h * 60 + Math.min(59, parseInt(v) || 0))}
          maxLength={2}
        />
        <Text style={styles.timeSep}>分</Text>
      </View>
    </View>
  );
}

export default function CategoryEditScreen({ route, navigation }: Props) {
  const { categoryId } = route.params ?? {};
  const { categories, addCategory, editCategory, removeCategory } = useCategoryStore();
  const existing = categories.find(c => c.id === categoryId);

  const [name, setName] = useState(existing?.name ?? '');
  const [type, setType] = useState<CategoryType>(existing?.type ?? 'quota');
  const [color, setColor] = useState(existing?.color ?? COLOR_OPTIONS[0]);
  const [weekdayMin, setWeekdayMin] = useState(existing?.weekday_budget_min ?? 0);
  const [weekendMin, setWeekendMin] = useState(existing?.weekend_budget_min ?? 0);

  const handleSave = () => {
    if (!name.trim()) { Alert.alert('エラー', 'カテゴリ名を入力してください'); return; }
    if (existing) {
      editCategory(existing.id, { name: name.trim(), type, color, weekday_budget_min: weekdayMin, weekend_budget_min: weekendMin });
    } else {
      addCategory({ name: name.trim(), type, color, weekday_budget_min: weekdayMin, weekend_budget_min: weekendMin });
    }
    navigation.goBack();
  };

  const handleDelete = () => {
    Alert.alert('削除', `「${existing?.name}」を削除しますか？`, [
      { text: 'キャンセル', style: 'cancel' },
      { text: '削除', style: 'destructive', onPress: () => { removeCategory(existing!.id); navigation.goBack(); } },
    ]);
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.container}>
        <View style={styles.field}>
          <Text style={styles.label}>カテゴリ名</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="例: 仕事"
            placeholderTextColor={COLORS.textMuted}
          />
        </View>

        <View style={styles.field}>
          <Text style={styles.label}>タイプ</Text>
          <View style={styles.typeRow}>
            {(['quota', 'limit'] as CategoryType[]).map(t => (
              <TouchableOpacity
                key={t}
                style={[styles.typeBtn, type === t && styles.typeBtnActive]}
                onPress={() => setType(t)}
              >
                <Text style={[styles.typeBtnText, type === t && styles.typeBtnTextActive]}>
                  {t === 'quota' ? 'ノルマ' : '上限'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.field}>
          <Text style={styles.label}>カラー</Text>
          <View style={styles.colorRow}>
            {COLOR_OPTIONS.map(c => (
              <TouchableOpacity
                key={c}
                style={[styles.colorDot, { backgroundColor: c }, color === c && styles.colorDotActive]}
                onPress={() => setColor(c)}
              />
            ))}
          </View>
        </View>

        <TimeInput label="平日の目標時間" minutes={weekdayMin} onChange={setWeekdayMin} />
        <TimeInput label="休日の目標時間" minutes={weekendMin} onChange={setWeekendMin} />

        {existing && (
          <TouchableOpacity style={styles.deleteBtn} onPress={handleDelete}>
            <Text style={styles.deleteBtnText}>このカテゴリを削除</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
          <Text style={styles.saveBtnText}>保存</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  container: { flex: 1, padding: SPACING.md },
  field: { marginBottom: SPACING.lg },
  label: { color: COLORS.textMuted, fontSize: 11, textTransform: 'uppercase', letterSpacing: 1, marginBottom: SPACING.sm },
  input: { backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: SPACING.md, color: COLORS.text, fontSize: 14, borderWidth: 1, borderColor: COLORS.border },
  typeRow: { flexDirection: 'row', gap: SPACING.sm },
  typeBtn: { flex: 1, backgroundColor: COLORS.surface, borderRadius: RADIUS.lg, padding: SPACING.md, alignItems: 'center', borderWidth: 2, borderColor: 'transparent' },
  typeBtnActive: { borderColor: COLORS.accent },
  typeBtnText: { color: COLORS.textMuted, fontSize: 14, fontWeight: 'bold' },
  typeBtnTextActive: { color: COLORS.accent },
  colorRow: { flexDirection: 'row', gap: SPACING.sm, flexWrap: 'wrap' },
  colorDot: { width: 32, height: 32, borderRadius: RADIUS.full },
  colorDotActive: { borderWidth: 3, borderColor: COLORS.white },
  timeRow: { flexDirection: 'row', alignItems: 'center', gap: SPACING.sm },
  timeInput: { backgroundColor: COLORS.surface, borderRadius: RADIUS.md, padding: SPACING.sm, color: COLORS.text, fontSize: 16, width: 52, textAlign: 'center', borderWidth: 1, borderColor: COLORS.border },
  timeSep: { color: COLORS.textMuted, fontSize: 13 },
  deleteBtn: { alignItems: 'center', padding: SPACING.md, marginBottom: SPACING.sm },
  deleteBtnText: { color: COLORS.dangerText, fontSize: 14 },
  saveBtn: { backgroundColor: COLORS.accent, borderRadius: RADIUS.lg, padding: SPACING.md, alignItems: 'center', marginBottom: SPACING.xl },
  saveBtnText: { color: COLORS.white, fontSize: 15, fontWeight: 'bold' },
});
```

- [ ] **Step 2: 動作確認**

```bash
npx expo start
```

Expected: 設定タブ → カテゴリ追加 → 名前・タイプ・カラー・時間を設定して保存 → カテゴリ一覧に表示される。今日タブにも反映される。

- [ ] **Step 3: コミット**

```bash
git add src/screens/CategoryEditScreen.tsx
git commit -m "feat: implement CategoryEditScreen with full CRUD"
```

---

## Task 21: 通知セットアップ

**Files:**
- Create: `src/utils/notifications.ts`

- [ ] **Step 1: 実装**

```typescript
// src/utils/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

export async function requestNotificationPermission(): Promise<boolean> {
  if (!Device.isDevice) return false;
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('timer', {
      name: 'タイマー通知',
      importance: Notifications.AndroidImportance.MAX,
    });
  }
  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

export async function scheduleTimerNotification(
  title: string,
  body: string,
  delaySeconds: number
): Promise<string> {
  return Notifications.scheduleNotificationAsync({
    content: { title, body, sound: true },
    trigger: { seconds: delaySeconds, repeats: false },
  });
}

export async function cancelNotification(notificationId: string): Promise<void> {
  await Notifications.cancelScheduledNotificationAsync(notificationId);
}
```

- [ ] **Step 2: コミット**

```bash
git add src/utils/notifications.ts
git commit -m "feat: add notification utilities"
```

---

## Task 22: タイマーと通知の連携

**Files:**
- Modify: `src/store/timerStore.ts`
- Modify: `App.tsx`

- [ ] **Step 1: timerStore に通知IDを追加**

```typescript
// src/store/timerStore.ts
import { create } from 'zustand';
import { startSession, stopSession, getInProgressSession } from '../db/sessions';
import { getLocalDateString } from '../utils/dateUtils';
import { scheduleTimerNotification, cancelNotification } from '../utils/notifications';

interface TimerState {
  activeSessionId: number | null;
  activeCategoryId: number | null;
  startedAt: number | null;
  notificationId: string | null;
  startTimer: (categoryId: number, categoryName: string, budgetSec: number) => void;
  stopTimer: () => void;
  restoreTimer: () => void;
}

export const useTimerStore = create<TimerState>((set, get) => ({
  activeSessionId: null,
  activeCategoryId: null,
  startedAt: null,
  notificationId: null,

  startTimer: async (categoryId, categoryName, budgetSec) => {
    if (get().activeSessionId !== null) return;
    const date = getLocalDateString();
    const sessionId = startSession(categoryId, date);
    const now = Math.floor(Date.now() / 1000);
    let notificationId: string | null = null;
    if (budgetSec > 0) {
      notificationId = await scheduleTimerNotification(
        `${categoryName}の時間になりました`,
        `設定時間 ${Math.floor(budgetSec / 60)} 分に達しました`,
        budgetSec,
      );
    }
    set({ activeSessionId: sessionId, activeCategoryId: categoryId, startedAt: now, notificationId });
  },

  stopTimer: async () => {
    const { activeSessionId, notificationId } = get();
    if (activeSessionId === null) return;
    stopSession(activeSessionId);
    if (notificationId) await cancelNotification(notificationId);
    set({ activeSessionId: null, activeCategoryId: null, startedAt: null, notificationId: null });
  },

  restoreTimer: () => {
    const session = getInProgressSession();
    if (session) {
      set({ activeSessionId: session.id, activeCategoryId: session.category_id, startedAt: session.started_at });
    }
  },
}));
```

- [ ] **Step 2: App.tsx で通知パーミッションをリクエスト**

```typescript
// App.tsx
import React, { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import AppNavigator from './src/navigation/AppNavigator';
import { initDb } from './src/db/schema';
import { useCategoryStore } from './src/store/categoryStore';
import { useTimerStore } from './src/store/timerStore';
import { requestNotificationPermission } from './src/utils/notifications';

export default function App() {
  useEffect(() => {
    initDb();
    useCategoryStore.getState().loadCategories();
    useTimerStore.getState().restoreTimer();
    requestNotificationPermission();
  }, []);

  return (
    <>
      <StatusBar style="light" />
      <AppNavigator />
    </>
  );
}
```

- [ ] **Step 3: TodayScreen の handlePress を更新**

`src/screens/TodayScreen.tsx` の `handlePress` を以下に変更する（budgetSec を渡すため）：

```typescript
const handlePress = (category: import('../db/categories').Category) => {
  if (activeCategoryId === category.id) {
    stopTimer();
  } else if (activeSessionId === null) {
    const budget = getBudgetForDate(category, now);
    startTimer(category.id, category.name, budget * 60);
  }
  setTimeout(refresh, 200);
};
```

`FlatList` の `renderItem` も合わせて変更：

```typescript
onPress={() => handlePress(item)}
```

- [ ] **Step 4: timerStore のテストを新しいシグネチャ用に更新**

```typescript
// src/store/__tests__/timerStore.test.ts の startTimer 呼び出しを更新
// 変更前: useTimerStore.getState().startTimer(1)
// 変更後:
useTimerStore.getState().startTimer(1, '仕事', 3600);
// stopTimer テストも同様に更新（startTimer に3引数渡す）
useTimerStore.getState().startTimer(1, '仕事', 3600);
// 2重起動テストも同様:
useTimerStore.getState().startTimer(1, '仕事', 3600);
useTimerStore.getState().startTimer(2, '趣味', 7200);
```

- [ ] **Step 5: 全テスト実行**

```bash
npx jest
```

Expected: 全テストが PASS

- [ ] **Step 5: 動作確認**

```bash
npx expo start
```

Expected:
- カテゴリをタップしてタイマーが起動する
- 目標時間に達するとpush通知が届く
- STOPを押すと通知がキャンセルされる

- [ ] **Step 6: コミット**

```bash
git add -A
git commit -m "feat: wire timer notifications to start/stop flow"
```

---

## 全テスト一括実行

```bash
npx jest --coverage
```

Expected: 全テスト PASS、主要なビジネスロジック（clearCheck, dateUtils, stores, DB queries）がカバーされている。
