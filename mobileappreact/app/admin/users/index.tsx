import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, FlatList, TextInput, RefreshControl } from 'react-native';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { ChevronLeft, Search, Ban, RotateCcw } from 'lucide-react-native';
import { useTheme } from '../../../src/theme';
import { api } from '../../../src/lib/api';
import { Card, Avatar, Badge, Chip, Skeleton, EmptyState, ErrorState, PressableScale } from '../../../src/components';
import { relativeTime } from '../../../src/lib/format';
import { enterList } from '../../../src/theme/motion';
import Animated from 'react-native-reanimated';
import { haptic } from '../../../src/lib/haptics';

const AURORA = require('../../../src/components/core/AppBackground').AppBackground;

export default function AdminUsers() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [tier, setTier] = useState('');
  const { data, isLoading, isError, refetch, isRefetching } = useQuery({
    queryKey: ['admin-users', search, role, tier],
    queryFn: () => api.adminUsers({ search: search || undefined, role: role || undefined, subscriptionTier: tier || undefined }),
  });

  const users = data?.users ?? [];

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AURORA />
      <View style={styles.header}>
        <PressableScale haptic="light" pressScale={0.9} onPress={() => router.back()} style={[styles.back, { backgroundColor: palette.surface, borderColor: palette.border }]}>
          <ChevronLeft size={22} color={palette.text} strokeWidth={2.2} />
        </PressableScale>
        <Text style={type.headingMedium(palette.text)}>Users</Text>
        <View style={{ width: 42 }} />
      </View>

      <View style={styles.searchHost}>
        <View style={[styles.search, { backgroundColor: palette.surface, borderColor: palette.border, borderRadius: radius.md }]}>
          <Search size={17} color={palette.textMuted} strokeWidth={2} />
          <TextInput
            placeholder="Search by name"
            placeholderTextColor={palette.textMuted}
            value={search}
            onChangeText={setSearch}
            autoCapitalize="none"
            style={[type.bodySmall(palette.text), { flex: 1, paddingVertical: 0 }]}
          />
        </View>
        <View style={styles.chips}>
          {['', 'user', 'therapist'].map((r) => (
            <Chip key={r} label={r === '' ? 'All roles' : r} selected={role === r} onPress={() => setRole(r)} />
          ))}
          {['', 'free', 'paid'].map((t) => (
            <Chip key={t} label={t === '' ? 'All tiers' : t} color="gold" selected={tier === t} onPress={() => setTier(t)} />
          ))}
        </View>
      </View>

      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1, 2, 3].map((i) => (
            <Skeleton key={i} height={84} radius={radius.lg} />
          ))}
        </View>
      ) : isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : users.length === 0 ? (
        <EmptyState title="No users found" body="Adjust the filters or search." />
      ) : (
        <FlatList
          data={users}
          keyExtractor={(u) => u.id}
          contentContainerStyle={{ padding: 20, gap: 12 }}
          refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={() => refetch()} tintColor={palette.teal} />}
          renderItem={({ item, index }) => <UserRow key={item.id} user={item} index={index} onToggle={async () => {
            haptic.medium();
            await qc.invalidateQueries({ queryKey: ['admin-users'] });
          }} />}
        />
      )}
    </View>
  );
}

function UserRow({
  user: u,
  index,
  onToggle,
}: {
  user: Awaited<ReturnType<typeof api.adminUsers>>['users'][number];
  index: number;
  onToggle: () => Promise<void>;
}) {
  const { palette, type, radius } = useTheme();
  const roleColor = u.role === 'admin' ? 'purple' : u.role === 'therapist' ? 'success' : 'teal';
  const toggle = async () => {
    haptic.medium();
    try {
      await api.adminUpdateUser(u.id, { isActive: !u.isActive });
      await onToggle();
    } catch {
      // surfaced by refetch
    }
  };
  return (
    <Animated.View entering={enterList(index)}>
      <PressableScale haptic="light" onPress={() => router.push(`/admin/users/${u.id}`)}>
        <Card padding={16}>
          <View style={styles.row}>
            <Avatar firstName={u.firstName} lastName={u.lastName} size={44} />
            <View style={{ flex: 1, marginLeft: 12 }}>
              <View style={styles.titleRow}>
                <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                  {u.firstName} {u.lastName}
                </Text>
                {!u.isActive && <Badge label="Suspended" color="danger" />}
              </View>
              <View style={[styles.badgeRow, { marginTop: 6 }]}>
                <Badge label={u.role} color={roleColor as never} />
                {u.subscriptionTier === 'paid' && <Badge label="Paid" color="gold" />}
                <Text style={type.micro(palette.textMuted)}>Joined {relativeTime(u.createdAt)}</Text>
              </View>
            </View>
            <PressableScale
              haptic="heavy"
              pressScale={0.85}
              onPress={toggle}
              style={[styles.action, { backgroundColor: u.isActive ? palette.dangerSoft : palette.successSoft, borderRadius: radius.pill }]}
            >
              {u.isActive ? (
                <Ban size={16} color={palette.danger} strokeWidth={2} />
              ) : (
                <RotateCcw size={16} color={palette.success} strokeWidth={2} />
              )}
            </PressableScale>
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
  searchHost: { paddingHorizontal: 20 },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
    height: 46,
    borderWidth: 1,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  skeletons: { padding: 20, gap: 12 },
  row: { flexDirection: 'row', alignItems: 'center' },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  badgeRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  action: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
});
