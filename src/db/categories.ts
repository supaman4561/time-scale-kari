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
