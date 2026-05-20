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
