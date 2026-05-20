import { mockDbInstance } from '../../../__mocks__/expo-sqlite';
import { useTimerStore } from '../timerStore';

beforeEach(() => {
  jest.clearAllMocks();
  useTimerStore.setState({
    activeSessionId: null, activeCategoryId: null, startedAt: null, notificationId: null,
  });
});

it('初期状態はタイマー停止', () => {
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBeNull();
  expect(s.activeCategoryId).toBeNull();
});

it('startTimer でセッションIDとカテゴリIDが設定される', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 7, changes: 1 });
  useTimerStore.getState().startTimer(1, '仕事', 3600);
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBe(7);
  expect(s.activeCategoryId).toBe(1);
  expect(s.startedAt).not.toBeNull();
});

it('startTimer を2回呼んでも2重起動しない', () => {
  mockDbInstance.runSync.mockReturnValue({ lastInsertRowId: 7, changes: 1 });
  useTimerStore.getState().startTimer(1, '仕事', 3600);
  useTimerStore.getState().startTimer(2, '趣味', 7200);
  expect(mockDbInstance.runSync).toHaveBeenCalledTimes(1);
  expect(useTimerStore.getState().activeCategoryId).toBe(1);
});

it('stopTimer でセッションが停止してnullに戻る', () => {
  useTimerStore.setState({ activeSessionId: 7, activeCategoryId: 1, startedAt: 0, notificationId: null });
  useTimerStore.getState().stopTimer();
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBeNull();
  expect(s.activeCategoryId).toBeNull();
});

it('restoreTimer: 進行中セッションがあればストアに反映する', () => {
  mockDbInstance.getFirstSync.mockReturnValue({
    id: 3, category_id: 2, date: '2026-05-20',
    started_at: 1000000, ended_at: null, duration_sec: null,
  });
  useTimerStore.getState().restoreTimer();
  const s = useTimerStore.getState();
  expect(s.activeSessionId).toBe(3);
  expect(s.activeCategoryId).toBe(2);
});
