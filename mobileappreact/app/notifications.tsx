import React, { useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { ChevronLeft, Bell, Flame, PhoneCall, CheckCircle2, Sparkles, BadgeCheck, XCircle } from 'lucide-react-native';
import { useTheme } from '../src/theme';
import { useNotifications } from '../src/lib/queries';
import { useAuthStore } from '../src/lib/auth-store';
import { api } from '../src/lib/api';
import { Screen, Skeleton, EmptyState, ErrorState, PressableScale } from '../src/components';
import { relativeTime } from '../src/lib/format';
import { enterList } from '../src/theme/motion';
import Animated from 'react-native-reanimated';
import type { NotificationModel } from '../src/lib/types';

import type { Palette } from '../src/theme/tokens';

function iconFor(type: string, palette: Palette): { Icon: typeof Bell; tint: string } {
  switch (type) {
    case 'streak_reminder':
      return { Icon: Flame, tint: palette.gold };
    case 'session_incoming':
    case 'session_completed':
      return { Icon: PhoneCall, tint: palette.teal };
    case 'subscription_active':
      return { Icon: Sparkles, tint: palette.gold };
    case 'therapist_approved':
      return { Icon: BadgeCheck, tint: palette.teal };
    case 'therapist_rejected':
      return { Icon: XCircle, tint: palette.danger };
    default:
      return { Icon: Bell, tint: palette.textSecondary };
  }
}

export default function NotificationsScreen() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((s) => s.user);
  const { data, isLoading, isError, refetch, isRefetching } = useNotifications(!!user);
  const items = data?.notifications ?? [];

  useEffect(() => {
    // Opening the screen marks everything read (mirrors Flutter behavior).
    if (data && data.unreadCount > 0) {
      api.readAllNotifications().catch(() => {});
    }
  }, [data?.unreadCount]);

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AURORA />
      <View style={styles.header}>
        <PressableScale haptic="light" pressScale={0.9} onPress={() => router.back()} style={[styles.back, { backgroundColor: palette.surface, borderColor: palette.border }]}>
          <ChevronLeft size={22} color={palette.text} strokeWidth={2.2} />
        </PressableScale>
        <Text style={type.headingMedium(palette.text)}>Notifications</Text>
        <View style={{ width: 42 }} />
      </View>
      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1, 2, 3].map((i) => (
            <Skeleton key={i} height={76} radius={radius.md} />
          ))}
        </View>
      ) : isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : items.length === 0 ? (
        <EmptyState title="All caught up" body="Notifications about your streak and sessions will appear here." />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(n) => n.id}
          contentContainerStyle={{ padding: 20, gap: 10 }}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={() => refetch()} tintColor={palette.teal} />}
          renderItem={({ item, index }) => (
            <NotificationRow index={index} item={item} />
          )}
        />
      )}
    </View>
  );
}

function NotificationRow({ item, index }: { item: NotificationModel; index: number }) {
  const { palette, type, radius } = useTheme();
  const { Icon, tint } = iconFor(item.type, palette);
  return (
    <Animated.View entering={enterList(index)}>
      <PressableScale haptic="light" onPress={() => router.push('/(tabs)')}>
        <View
          style={[
            styles.row,
            {
              backgroundColor: palette.surface,
              borderColor: palette.border,
              borderRadius: radius.md,
              opacity: item.isRead ? 0.75 : 1,
            },
          ]}
        >
          <View
            style={[
              styles.icon,
              {
                backgroundColor: `${tint}${item.isRead ? '14' : '26'}`,
                borderRadius: radius.pill,
              },
            ]}
          >
            <Icon size={18} color={tint} strokeWidth={1.9} />
          </View>
          <View style={{ flex: 1 }}>
            <View style={styles.titleRow}>
              <Text style={[type.headingSmall(palette.text), { fontSize: 14 }]} numberOfLines={1}>
                {item.title}
              </Text>
              {!item.isRead && <View style={[styles.dot, { backgroundColor: palette.teal }]} />}
            </View>
            <Text style={[type.bodySmall(palette.textSecondary), styles.body]} numberOfLines={2}>
              {item.body}
            </Text>
            <Text style={[type.micro(palette.textMuted), { marginTop: 4 }]}>{relativeTime(item.createdAt)}</Text>
          </View>
        </View>
      </PressableScale>
    </Animated.View>
  );
}

const AURORA = require('../src/components/core/AppBackground').AppBackground;

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
  back: {
    width: 42,
    height: 42,
    borderRadius: 21,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  skeletons: { padding: 20, gap: 10 },
  row: {
    flexDirection: 'row',
    gap: 14,
    padding: 14,
    borderWidth: 1,
  },
  icon: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  dot: { width: 8, height: 8, borderRadius: 4 },
  body: { marginTop: 2 },
});
