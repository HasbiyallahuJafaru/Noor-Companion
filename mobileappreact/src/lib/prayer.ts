import { useQuery } from '@tanstack/react-query';
import * as Location from 'expo-location';
import { useEffect, useState } from 'react';
import { api } from './api';
import { config } from './config';
import { demoPrayerTimes } from './fixtures';
import { cacheGet, cacheKeys, cacheSet } from './cache';
import type { PrayerTimesModel } from './types';

export type PrayerStatus =
  | { state: 'loading' }
  | { state: 'ready'; data: PrayerTimesModel; cached: boolean }
  | { state: 'denied' }
  | { state: 'error' };

/**
 * Location-aware prayer times with an AsyncStorage cache, mirroring the
 * Flutter geolocator + Hive flow. Polls the countdown every 60s upstream.
 */
export function usePrayerTimes(enabled: boolean) {
  const [status, setStatus] = useState<PrayerStatus>({ state: 'loading' });
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    (async () => {
      setStatus({ state: 'loading' });
      if (config.demoMode) {
        await new Promise((r) => setTimeout(r, 400));
        if (alive) setStatus({ state: 'ready', data: demoPrayerTimes, cached: false });
        return;
      }
      const cached = await cacheGet<PrayerTimesModel>(cacheKeys.prayerTimes);
      if (cached && alive) setStatus({ state: 'ready', data: cached, cached: true });
      try {
        const perm = await Location.getForegroundPermissionsAsync();
        if (!perm.granted) {
          if (cached && alive) return; // keep showing cached data
          if (alive) setStatus({ state: 'denied' });
          return;
        }
        const pos = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });
        const fresh = await api.prayerTimes(pos.coords.latitude, pos.coords.longitude);
        await cacheSet(cacheKeys.prayerTimes, fresh);
        if (alive) setStatus({ state: 'ready', data: fresh, cached: false });
      } catch {
        if (!cached && alive) setStatus({ state: 'error' });
      }
    })();
    return () => {
      alive = false;
    };
  }, [enabled, reloadKey]);

  return { status, reload: () => setReloadKey((k) => k + 1) };
}

/** Live "next prayer" name + countdown, ticking every 30 seconds. */
export function useNextPrayer(prayer: PrayerTimesModel | null) {
  const [, force] = useState(0);
  useEffect(() => {
    const id = setInterval(() => force((n) => n + 1), 30_000);
    return () => clearInterval(id);
  }, []);

  if (!prayer) return { name: 'Fajr', countdown: '' };
  const list: [string, number][] = (
    [
      ['Fajr', prayer.fajr],
      ['Sunrise', prayer.sunrise],
      ['Dhuhr', prayer.dhuhr],
      ['Asr', prayer.asr],
      ['Maghrib', prayer.maghrib],
      ['Isha', prayer.isha],
    ] as [string, string][]
  ).map(([name, t]) => {
    const [h, m] = t.split(':').map((x) => parseInt(x, 10));
    return [name, (Number.isNaN(h) ? 0 : h) * 60 + (Number.isNaN(m) ? 0 : m)];
  });

  const now = new Date();
  const cur = now.getHours() * 60 + now.getMinutes();
  for (const [name, mins] of list) {
    if (mins > cur) {
      let diff = mins - cur;
      return { name, countdown: `${Math.floor(diff / 60)}h ${diff % 60}m` };
    }
  }
  return { name: 'Fajr', countdown: '' };
}
