import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from './api';
import { cacheGet, cacheKeys, cacheSet } from './cache';
import type { DhikrModel, DuaModel, RecitationModel } from './types';

/** Content queries fall back to the AsyncStorage cache while offline. */
function useCachedContent<T>(
  key: keyof typeof cacheKeys,
  fetcher: () => Promise<T>,
  enabled = true,
) {
  return useQuery({
    queryKey: ['content', key],
    queryFn: async () => {
      try {
        const fresh = await fetcher();
        await cacheSet(cacheKeys[key], fresh);
        return fresh;
      } catch (err) {
        const cached = await cacheGet<T>(cacheKeys[key]);
        if (cached) return cached;
        throw err;
      }
    },
    enabled,
    staleTime: 1000 * 60 * 30,
  });
}

export const useDhikr = (tag?: string) =>
  useQuery({
    queryKey: ['dhikr', tag ?? 'all'],
    queryFn: async () => {
      try {
        const fresh = await api.dhikr(tag && tag !== 'all' ? tag : undefined);
        if (!tag || tag === 'all') await cacheSet(cacheKeys.dhikr, fresh);
        return fresh;
      } catch (err) {
        const cached = await cacheGet<DhikrModel[]>(cacheKeys.dhikr);
        if (cached && (!tag || tag === 'all')) return cached;
        throw err;
      }
    },
    staleTime: 1000 * 60 * 30,
  });

export const useDuas = (occasion?: string) =>
  useQuery({
    queryKey: ['duas', occasion ?? 'all'],
    queryFn: async () => {
      try {
        const fresh = await api.duas(occasion && occasion !== 'all' ? occasion : undefined);
        if (!occasion || occasion === 'all') await cacheSet(cacheKeys.duas, fresh);
        return fresh;
      } catch (err) {
        const cached = await cacheGet<DuaModel[]>(cacheKeys.duas);
        if (cached && (!occasion || occasion === 'all')) return cached;
        throw err;
      }
    },
    staleTime: 1000 * 60 * 30,
  });

export const useRecitations = () =>
  useCachedContent<RecitationModel[]>('recitations', () => api.recitations());

export const useSurah = (surahNumber: number) =>
  useQuery({
    queryKey: ['surah', surahNumber],
    queryFn: () => api.surah(surahNumber),
    staleTime: 1000 * 60 * 60 * 24,
  });

/** Record content progress; invalidates streak data everywhere. */
export function useRecordProgress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (contentId: string) => api.recordProgress(contentId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['streak'] });
      qc.invalidateQueries({ queryKey: ['me'] });
    },
  });
}

export const useStreak = (enabled: boolean) =>
  useQuery({ queryKey: ['streak'], queryFn: () => api.myStreak(), enabled });

export const useNotifications = (enabled: boolean) =>
  useQuery({
    queryKey: ['notifications'],
    queryFn: () => api.notifications(),
    enabled,
    refetchInterval: 1000 * 60,
  });

export const useTherapists = (params: { specialisation?: string; language?: string }) =>
  useQuery({
    queryKey: ['therapists', params],
    queryFn: () => api.therapists({ limit: 50, ...params }),
  });

export const useTherapist = (id: string) =>
  useQuery({ queryKey: ['therapist', id], queryFn: () => api.therapist(id) });
