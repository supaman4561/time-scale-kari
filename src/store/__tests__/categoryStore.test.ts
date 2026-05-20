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
