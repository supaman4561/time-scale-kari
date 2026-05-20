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
    'UPDATE sessions SET ended_at = ?, duration_sec = ? - started_at WHERE id = ?',
    endedAt, endedAt, sessionId,
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

export function getMonthTotals(year: number, month: number): Record<string, Record<number, number>> {
  const prefix = `${year}-${String(month + 1).padStart(2, '0')}`;
  const rows = getDb().getAllSync<{ date: string; category_id: number; total: number }>(
    `SELECT date, category_id,
     SUM(CASE WHEN ended_at IS NOT NULL THEN duration_sec
              ELSE CAST(strftime('%s','now') AS INTEGER) - started_at END) AS total
     FROM sessions WHERE date LIKE ? GROUP BY date, category_id`,
    `${prefix}%`,
  );
  const result: Record<string, Record<number, number>> = {};
  for (const r of rows) {
    if (!result[r.date]) result[r.date] = {};
    result[r.date][r.category_id] = r.total ?? 0;
  }
  return result;
}
