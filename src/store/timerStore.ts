import { create } from 'zustand';
import { startSession, stopSession, getInProgressSession } from '../db/sessions';
import { getLocalDateString } from '../utils/dateUtils';

interface TimerState {
  activeSessionId: number | null;
  activeCategoryId: number | null;
  startedAt: number | null;
  notificationId: string | null;
  startTimer: (categoryId: number, categoryName: string, budgetSec: number) => void;
  stopTimer: () => void;
  restoreTimer: () => void;
  setNotificationId: (id: string | null) => void;
}

export const useTimerStore = create<TimerState>((set, get) => ({
  activeSessionId: null,
  activeCategoryId: null,
  startedAt: null,
  notificationId: null,

  startTimer: (categoryId, _categoryName, _budgetSec) => {
    if (get().activeSessionId !== null) return;
    const date = getLocalDateString();
    const sessionId = startSession(categoryId, date);
    set({
      activeSessionId: sessionId,
      activeCategoryId: categoryId,
      startedAt: Math.floor(Date.now() / 1000),
    });
  },

  stopTimer: () => {
    const { activeSessionId } = get();
    if (activeSessionId === null) return;
    stopSession(activeSessionId);
    set({ activeSessionId: null, activeCategoryId: null, startedAt: null, notificationId: null });
  },

  restoreTimer: () => {
    const session = getInProgressSession();
    if (session) {
      set({
        activeSessionId: session.id,
        activeCategoryId: session.category_id,
        startedAt: session.started_at,
      });
    }
  },

  setNotificationId: (id) => set({ notificationId: id }),
}));
