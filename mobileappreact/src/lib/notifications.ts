import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';
import { api } from './api';

/** Foreground: show heads-up banners. */
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

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

/** Register the device push token with the API. Skips quietly in Expo Go. */
export async function registerPushToken() {
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

/** Wire tap routing; call once near the root. */
export function useNotificationRouting() {
  const router = useRouter();
  useEffect(() => {
    const sub = Notifications.addNotificationResponseReceivedListener((res) => {
      const target = routeFor(res.notification.request.content.data as Record<string, unknown>);
      if (target) router.push(target as never);
    });
    return () => sub.remove();
  }, [router]);
}
