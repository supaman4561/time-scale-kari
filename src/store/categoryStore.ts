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
