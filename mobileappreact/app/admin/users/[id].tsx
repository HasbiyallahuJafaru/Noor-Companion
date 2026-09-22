import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Crown, Ban, RotateCcw } from 'lucide-react-native';
import { useTheme } from '../../../src/theme';
import { api } from '../../../src/lib/api';
import { Screen, Card, GlassCard, Avatar, Badge, Button, Skeleton, ErrorState, PressableScale } from '../../../src/components';
import { relativeTime } from '../../../src/lib/format';
import { haptic } from '../../../src/lib/haptics';

export default function AdminUserDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { palette, type, radius } = useTheme();
  const qc = useQueryClient();
  const { data: u, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-user', id],
    queryFn: () => api.adminUser(String(id)),
  });
  const [busy, setBusy] = useState(false);

  if (isLoading) {
    return (
      <Screen back title="User">
        <View style={{ padding: 20, gap: 14 }}>
          <Skeleton height={110} radius={radius.lg} />
          <Skeleton height={130} radius={radius.lg} />
        </View>
      </Screen>
    );
  }
  if (isError || !u) {
    return (
      <Screen back title="User">
        <ErrorState onRetry={() => refetch()} />
      </Screen>
    );
  }

  const roleColor = u.role === 'admin' ? 'purple' : u.role === 'therapist' ? 'success' : 'teal';

  const patch = async (body: { isActive?: boolean; subscriptionTier?: 'free' | 'paid' }) => {
    setBusy(true);
    try {
      await api.adminUpdateUser(u.id, body);
      haptic.success();
      await qc.invalidateQueries({ queryKey: ['admin-user', id] });
      await qc.invalidateQueries({ queryKey: ['admin-users'] });
    } catch (e) {
      Alert.alert('Update failed', e instanceof Error ? e.message : 'Please try again.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen back title={`${u.firstName} ${u.lastName}`}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <GlassCard animate={false} padding={20}>
          <View style={styles.heroRow}>
            <Avatar firstName={u.firstName} lastName={u.lastName} size={64} />
            <View style={{ flex: 1, marginLeft: 14 }}>
              <View style={styles.nameRow}>
                <Text style={type.headingSmall(palette.text)}>
                  {u.firstName} {u.lastName}
                </Text>
                {!u.isActive && <Badge label="Suspended" color="danger" />}
              </View>
              <View style={[styles.badgeRow, { marginTop: 8 }]}>
                <Badge label={u.role} color={roleColor as never} />
                <Badge label={u.subscriptionTier === 'paid' ? 'Paid' : 'Free'} color={u.subscriptionTier === 'paid' ? 'gold' : 'muted'} />
              </View>
            </View>
          </View>
          <View style={[styles.meta, { borderTopColor: palette.hairline }]}>
            <MetaRow label="User ID" value={u.id} />
            <MetaRow label="Supabase ID" value={u.supabaseId} />
            <MetaRow label="Joined" value={relativeTime(u.createdAt)} />
          </View>
        </GlassCard>

        <Card style={styles.section}>
          <Text style={type.headingSmall(palette.text)}>Streak</Text>
          <View style={styles.streakRow}>
            <Stat label="Current" value={String(u.currentStreak ?? 0)} />
            <Stat label="Longest" value={String(u.longestStreak ?? 0)} />
            <Stat label="Total days" value={String(u.totalDays ?? 0)} />
          </View>
          <Text style={[type.micro(palette.textMuted), { marginTop: 10 }]}>
            Last active: {u.lastEngagedAt ? relativeTime(u.lastEngagedAt) : 'Never'}
          </Text>
        </Card>

        <Card style={styles.section}>
          <Text style={type.headingSmall(palette.text)}>Actions</Text>
          <View style={{ marginTop: 14, gap: 10 }}>
            <Button
              label={u.isActive ? 'Suspend Account' : 'Restore Account'}
              variant={u.isActive ? 'danger' : 'primary'}
              icon={u.isActive ? <Ban size={16} color="#FFFFFF" strokeWidth={2} /> : <RotateCcw size={16} color="#FFFFFF" strokeWidth={2} />}
              loading={busy}
              onPress={() =>
                Alert.alert(
                  u.isActive ? 'Suspend account' : 'Restore account',
                  u.isActive
                    ? `${u.firstName} will lose access until restored.`
                    : `${u.firstName} will regain full access.`,
                  [
                    { text: 'Cancel', style: 'cancel' },
                    { text: 'Confirm', style: 'destructive', onPress: () => patch({ isActive: !u.isActive }) },
                  ],
                )
              }
            />
            {u.subscriptionTier !== 'paid' && (
              <Button
                label="Grant Paid Access"
                variant="gold"
                icon={<Crown size={16} color="#FFFFFF" strokeWidth={2} />}
                loading={busy}
                onPress={() =>
                  Alert.alert(
                    'Grant paid access',
                    `Activate a paid subscription for ${u.firstName}?`,
                    [
                      { text: 'Cancel', style: 'cancel' },
                      { text: 'Grant', onPress: () => patch({ subscriptionTier: 'paid' }) },
                    ],
                  )
                }
              />
            )}
          </View>
        </Card>
      </ScrollView>
    </Screen>
  );
}

function MetaRow({ label, value }: { label: string; value: string }) {
  const { palette, type } = useTheme();
  return (
    <View style={styles.metaRow}>
      <Text style={type.caption(palette.textMuted)}>{label}</Text>
      <Text style={[type.bodySmall(palette.textSecondary), { flexShrink: 1, marginLeft: 12, textAlign: 'right' }]} numberOfLines={1}>
        {value}
      </Text>
    </View>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  const { palette, type, radius } = useTheme();
  return (
    <View style={[styles.stat, { backgroundColor: palette.backgroundElevated, borderRadius: radius.md }]}>
      <Text style={type.headingSmall(palette.text)}>{value}</Text>
      <Text style={type.micro(palette.textMuted)}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, paddingBottom: 40 },
  heroRow: { flexDirection: 'row', alignItems: 'center' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  badgeRow: { flexDirection: 'row', gap: 8 },
  meta: { borderTopWidth: StyleSheet.hairlineWidth, marginTop: 18, paddingTop: 6 },
  metaRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 8 },
  section: { marginTop: 14 },
  streakRow: { flexDirection: 'row', gap: 10, marginTop: 14 },
  stat: { flex: 1, alignItems: 'center', paddingVertical: 12, gap: 3 },
});
