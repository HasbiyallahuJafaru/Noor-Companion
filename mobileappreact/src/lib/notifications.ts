import { Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';
import Constants, { ExecutionEnvironment } from 'expo-constants';
import { api } from './api';

/**
 * Push notifications, loaded lazily so the app still runs in Expo Go.
 *
 * Expo removed Android push from Expo Go in SDK 53, and expo-notifications
 * throws as soon as it is touched there. This module used to import it at the
 * top level and call setNotificationHandler during module evaluation, which
 * took down the whole router before the first screen rendered. Nothing here
 * loads the module until something actually needs it, and never in Expo Go.
 *
 * Everything below degrades to a no-op rather than throwing: push simply does
 * not work in Expo Go, which is expected. Use a development build for it.
 */
type NotificationsModule = typeof import('expo-notifications');

export const isExpoGo =
  Constants.executionEnvironment === ExecutionEnvironment.StoreClient;

let cached: NotificationsModule | null | undefined;

/** Returns the native module, or null where it is unavailable. */
function getNotifications(): NotificationsModule | null {
  if (cached !== undefined) return cached;
  if (isExpoGo) {
    cached = null;
    return null;
  }
  try {
    cached = require('expo-notifications') as NotificationsModule;
    cached.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowBanner: true,
        shouldShowList: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
      }),
    });
  } catch {
    cached = null;
  }
  return cached;
}

/** Map push data to routes, mirroring the Flutter notification_handler. */
function routeFor(data?: Record<string, unknown>): string | null {
  if (!data) return null;
  const type = String(data.type ?? '');
  switch (type) {
    case 'morning_reminder':
    case 'evening_reflection':
    case 'task_reminder':
      return '/(tabs)';
    case 'therapist_available':
      return `/therapists/${data.therapistId ?? ''}`;
    case 'milestone_unlocked':
      return `/milestone/${data.days ?? 7}`;
    case 'session_incoming':
      return '/incoming-call';
    default:
      return '/(tabs)';
  }
}

/** Register the device push token with the API. No-ops in Expo Go. */
export async function registerPushToken() {
  const Notifications = getNotifications();
  if (!Notifications) return;
  try {
    const existing = await Notifications.getPermissionsAsync();
    let granted = existing.granted;
    if (!granted) {
      const req = await Notifications.requestPermissionsAsync();
      granted = req.granted;
    }
    if (!granted) return;
    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('default', {
        name: 'General',
        importance: Notifications.AndroidImportance.HIGH,
        lightColor: '#0D9488',
      });
    }
    const token = await Notifications.getDevicePushTokenAsync();
    await api.registerFcmToken(token.data);
  } catch {
    // Requires a development build; unavailable in Expo Go.
  }
}

/** Wire tap routing; call once near the root. No-ops in Expo Go. */
export function useNotificationRouting() {
  const router = useRouter();
  useEffect(() => {
    const Notifications = getNotifications();
    if (!Notifications) return;
    const sub = Notifications.addNotificationResponseReceivedListener((res) => {
      const target = routeFor(res.notification.request.content.data as Record<string, unknown>);
      if (target) router.push(target as never);
    });
    return () => sub.remove();
  }, [router]);
}
