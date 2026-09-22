import AsyncStorage from '@react-native-async-storage/async-storage';

/** AsyncStorage-backed JSON cache, mirroring the Flutter Hive boxes. */
export const cacheKeys = {
  dhikr: 'dhikr_cache',
  duas: 'duas_cache',
  recitations: 'recitations_cache',
  prayerTimes: 'prayer_times_cache',
  bookmarks: 'bookmarks_cache',
  onboarding: 'onboarding',
  themePreference: 'theme_preference',
} as const;

export async function cacheGet<T>(key: string): Promise<T | null> {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    return null;
  }
}

export async function cacheSet<T>(key: string, value: T): Promise<void> {
  try {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Cache failures are never fatal.
  }
}

export async function cacheRemove(key: string): Promise<void> {
  try {
    await AsyncStorage.removeItem(key);
  } catch {
    // ignore
  }
}
