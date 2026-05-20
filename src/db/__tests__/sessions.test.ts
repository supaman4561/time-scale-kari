import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { startSession, stopSession, getSessionsForDate, getTotalSecByCategory, getInProgressSession } from '../sessions';

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
