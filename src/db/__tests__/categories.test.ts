import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { getAllCategories, insertCategory, updateCategory, deleteCategory } from '../categories';

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
