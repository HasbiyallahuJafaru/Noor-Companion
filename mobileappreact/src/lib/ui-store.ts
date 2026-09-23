import { create } from 'zustand';
import { cacheGet, cacheKeys, cacheSet } from './cache';
import type { ThemeMode } from '../theme';

interface UiState {
  themePreference: ThemeMode;
  bookmarks: string[];
  hydrated: boolean;
  hydrate: () => Promise<void>;
  setThemePreference: (m: ThemeMode) => Promise<void>;
  toggleBookmark: (duaId: string) => Promise<void>;
}

export const useUiStore = create<UiState>((set, get) => ({
  // Light is the product default. Anyone who has already chosen a theme
  // keeps it — only the value used when nothing is stored changes.
  themePreference: 'light',
  bookmarks: [],
  hydrated: false,

  hydrate: async () => {
    const theme = (await cacheGet<ThemeMode>(cacheKeys.themePreference)) ?? 'light';
    const bookmarks = (await cacheGet<string[]>(cacheKeys.bookmarks)) ?? [];
    set({ themePreference: theme, bookmarks, hydrated: true });
  },

  setThemePreference: async (m) => {
    set({ themePreference: m });
    await cacheSet(cacheKeys.themePreference, m);
  },

  toggleBookmark: async (duaId) => {
    const next = get().bookmarks.includes(duaId)
      ? get().bookmarks.filter((id) => id !== duaId)
      : [...get().bookmarks, duaId];
    set({ bookmarks: next });
    await cacheSet(cacheKeys.bookmarks, next);
  },
}));
