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
