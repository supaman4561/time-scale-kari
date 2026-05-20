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
