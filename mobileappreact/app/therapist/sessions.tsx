import React from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl } from 'react-native';
import { router } from 'expo-router';
import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Star } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { Card, Avatar, Badge, Skeleton, EmptyState, ErrorState, Button, PressableScale } from '../../src/components';
import { relativeTime, formatDuration } from '../../src/lib/format';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';
import type { CallSessionSummary } from '../../src/lib/types';

const AURORA = require('../../src/components/core/AuroraBackground').AuroraBackground;

export default function SessionHistory() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const {
    data,
    isLoading,
    isError,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['my-sessions'],
    queryFn: ({ pageParam }) => api.mySessions(pageParam),
    initialPageParam: 1,
    getNextPageParam: (last) => {
      const { pagination } = last;
      return pagination.page * pagination.limit < pagination.total
        ? pagination.page + 1
        : undefined;
    },
  });

  const sessions = data?.pages.flatMap((p) => p.sessions) ?? [];

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AURORA />
      <View style={styles.header}>
        <PressableScale haptic="light" pressScale={0.9} onPress={() => router.back()} style={[styles.back, { backgroundColor: palette.surface, borderColor: palette.border }]}>
          <Text style={type.headingSmall(palette.text)}>←</Text>
        </PressableScale>
        <Text style={type.headingMedium(palette.text)}>Session History</Text>
        <View style={{ width: 42 }} />
      </View>

      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} height={96} radius={radius.lg} />
          ))}
        </View>
      ) : isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : sessions.length === 0 ? (
        <EmptyState title="No sessions yet" body="Your completed sessions will appear here." />
      ) : (
        <FlatList
          data={sessions}
          keyExtractor={(s) => s.id}
          contentContainerStyle={{ padding: 20, gap: 12 }}
          refreshControl={<RefreshControl refreshing={false} onRefresh={() => refetch()} tintColor={palette.teal} />}
          renderItem={({ item, index }) => <SessionCard index={index} session={item} />}
          ListFooterComponent={
            hasNextPage ? (
              <View style={{ marginTop: 6 }}>
                <Button label={isFetchingNextPage ? 'Loading…' : 'Load More'} variant="outline" size="md" onPress={() => fetchNextPage()} />
              </View>
            ) : null
          }
        />
      )}
    </View>
  );
}

function SessionCard({ session: s, index }: { session: CallSessionSummary; index: number }) {
  const { palette, type, radius } = useTheme();
  const statusColor =
    s.status === 'completed' ? 'success' : s.status === 'active' ? 'teal' : s.status === 'initiated' ? 'muted' : 'danger';
  const name = `${s.callerFirstName ?? ''} ${s.callerLastName ?? ''}`.trim() || 'Unknown User';
  return (
    <Animated.View entering={enterList(index)}>
      <PressableScale haptic="light">
        <Card padding={16}>
          <View style={styles.row}>
            <Avatar url={s.callerAvatarUrl} firstName={s.callerFirstName ?? ''} lastName={s.callerLastName ?? ''} size={44} />
            <View style={{ flex: 1, marginLeft: 12 }}>
              <View style={styles.titleRow}>
                <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                  {name}
                </Text>
                <Badge label={s.status} color={statusColor as never} />
              </View>
              <Text style={[type.caption(palette.textMuted), { marginTop: 4 }]}>
                {s.durationSeconds ? formatDuration(s.durationSeconds) : 'Incomplete'} · {relativeTime(s.createdAt)}
              </Text>
              {typeof s.rating === 'number' && s.rating > 0 && (
                <View style={styles.stars}>
                  {[1, 2, 3, 4, 5].map((i) => (
                    <Star key={i} size={12} color={i <= (s.rating ?? 0) ? palette.gold : palette.borderStrong} fill={i <= (s.rating ?? 0) ? palette.gold : 'transparent'} strokeWidth={0} />
                  ))}
                </View>
              )}
            </View>
          </View>
        </Card>
      </PressableScale>
    </Animated.View>
  );
}

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
  skeletons: { padding: 20, gap: 12 },
  row: { flexDirection: 'row', alignItems: 'center' },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  stars: { flexDirection: 'row', gap: 2, marginTop: 5 },
});
