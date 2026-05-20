import { getLocalDateString, isWeekend, getBudgetForDate } from '../dateUtils';

describe('getLocalDateString', () => {
  it('Date オブジェクトから YYYY-MM-DD を返す', () => {
    const d = new Date(2026, 4, 20);
    expect(getLocalDateString(d)).toBe('2026-05-20');
  });
  it('引数なしで今日の日付を返す', () => {
    const result = getLocalDateString();
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

describe('isWeekend', () => {
  it('日曜は休日', () => {
    expect(isWeekend(new Date(2026, 4, 17))).toBe(true);
  });
  it('土曜は休日', () => {
    expect(isWeekend(new Date(2026, 4, 16))).toBe(true);
  });
  it('平日は false', () => {
    expect(isWeekend(new Date(2026, 4, 20))).toBe(false);
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
