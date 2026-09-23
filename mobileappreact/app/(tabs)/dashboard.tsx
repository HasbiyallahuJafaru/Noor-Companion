import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router, useFocusEffect } from 'expo-router';
import { Hourglass, XCircle, Pencil, History, Star, Briefcase, Activity } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { useAuthStore } from '../../src/lib/auth-store';
import { Screen, GlassCard, Card, Button, Skeleton, ErrorState, Avatar, Badge, PressableScale } from '../../src/components';
import { formatNgnShort } from '../../src/lib/format';

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

export default function TherapistDashboard() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((s) => s.user);
  const qc = useQueryClient();
  const { data: profile, isLoading, isError, refetch } = useQuery({
    queryKey: ['therapist-me'],
    queryFn: () => api.myTherapistProfile(),
  });

  useFocusEffect(
    React.useCallback(() => {
      qc.invalidateQueries({ queryKey: ['therapist-me'] });
    }, [qc]),
  );

  if (isLoading) {
    return (
      <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top + 18 }]}>
        <AURORA />
        <View style={{ padding: 20, gap: 14 }}>
          <Skeleton height={110} radius={radius.lg} />
          <Skeleton height={90} radius={radius.lg} />
        </View>
      </View>
    );
  }

  // Pending / rejected gate.
  if (!profile || profile.status !== 'active') {
    const rejected = profile?.status === 'rejected';
    return (
      <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top + 18 }]}>
        <AURORA />
        <View style={[styles.pendingWrap, { flex: 1 }]}>
          <View style={[styles.pendingIcon, { backgroundColor: rejected ? palette.dangerSoft : palette.goldSoft }]}>
            {rejected ? (
              <XCircle size={34} color={palette.danger} strokeWidth={1.75} />
            ) : (
              <Hourglass size={34} color={palette.gold} strokeWidth={1.75} />
            )}
          </View>
          <Text style={[type.heading(palette.text), { textAlign: 'center', marginTop: 20 }]}>
            {rejected ? 'Application Not Approved' : 'Application Under Review'}
          </Text>
          <Text style={[type.body(palette.textSecondary), styles.pendingBody]}>
            {rejected
              ? profile?.rejectionReason
                ? `Reason: ${profile.rejectionReason}`
                : 'Unfortunately your application was not approved at this time.'
              : 'Our team reviews new therapist applications within 2-3 business days. Check back soon.'}
          </Text>
          <View style={{ marginTop: 26, alignSelf: 'stretch' }}>
            <Button label="Check Status" variant="outline" onPress={() => refetch()} />
          </View>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <ScrollView contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: insets.bottom + 140 }} showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={false} onRefresh={() => refetch()} tintColor={palette.teal} />}
      >
        <View style={styles.headerRow}>
          <View style={{ flex: 1 }}>
            <Text style={type.heading(palette.text)}>My Dashboard</Text>
            <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 2 }]}>Therapist workspace</Text>
          </View>
          <PressableScale haptic="light" onPress={() => router.push('/therapist/edit-profile')} style={[styles.editBtn, { backgroundColor: palette.surface, borderColor: palette.border }]}>
            <Pencil size={18} color={palette.text} strokeWidth={1.9} />
          </PressableScale>
        </View>

        {/* Profile card */}
        <AnimatedCard>
          <GlassCard padding={18}>
            <View style={styles.profileRow}>
              <Avatar url={profile.avatarUrl} firstName={profile.firstName} lastName={profile.lastName} size={56} />
              <View style={{ flex: 1, marginLeft: 14 }}>
                <View style={styles.nameRow}>
                  <Text style={type.headingSmall(palette.text)}>
                    {profile.firstName} {profile.lastName}
                  </Text>
                  <Badge label="Active" color="success" />
                </View>
                <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 3 }]} numberOfLines={1}>
                  {profile.specialisations.slice(0, 2).join(' · ')}
                </Text>
                <Text style={[type.caption(palette.goldDeep), { marginTop: 4 }]}>
                  {formatNgnShort(profile.sessionRateNgn)} / session
                </Text>
              </View>
            </View>
          </GlassCard>
        </AnimatedCard>

        {/* Stats */}
        <View style={styles.statRow}>
          <StatCard icon={Briefcase} tint={palette.teal} tintBg={palette.tealSoft} value={String(profile.totalSessions)} label="Sessions" />
          <StatCard icon={Star} tint={palette.gold} tintBg={palette.goldSoft} value={profile.averageRating ? profile.averageRating.toFixed(1) : '—'} label="Avg Rating" />
          <StatCard icon={Activity} tint={palette.purple} tintBg={palette.purpleSoft} value={`${profile.yearsExperience}y`} label="Experience" />
        </View>

        {/* Quick actions */}
        <Text style={[type.headingMedium(palette.text), styles.sectionTitle]}>Quick Actions</Text>
        <Card style={{ marginHorizontal: 20 }}>
          <PressableScale haptic="light" onPress={() => router.push('/therapist/sessions')} style={{ paddingVertical: 4 }}>
            <View style={styles.actionRow}>
              <History size={18} color={palette.teal} strokeWidth={1.9} />
              <Text style={[type.body(palette.textBody), { flex: 1, marginLeft: 12 }]}>Session History</Text>
            </View>
          </PressableScale>
          <PressableScale haptic="light" onPress={() => router.push('/therapist/edit-profile')} style={{ paddingVertical: 4 }}>
            <View style={styles.actionRow}>
              <Pencil size={18} color={palette.teal} strokeWidth={1.9} />
              <Text style={[type.body(palette.textBody), { flex: 1, marginLeft: 12 }]}>Edit Profile</Text>
            </View>
          </PressableScale>
        </Card>
      </ScrollView>
    </View>
  );
}

function StatCard({ icon: Icon, tint, tintBg, value, label }: { icon: typeof Star; tint: string; tintBg: string; value: string; label: string }) {
  const { palette, type, radius } = useTheme();
  return (
    <Card padding={14} style={{ flex: 1, alignItems: 'flex-start', height: 96, justifyContent: 'space-between' }}>
      <View style={[styles.statIcon, { backgroundColor: tintBg, borderRadius: radius.sm }]}>
        <Icon size={16} color={tint} strokeWidth={1.9} />
      </View>
      <View>
        <Text style={type.headingSmall(palette.text)}>{value}</Text>
        <Text style={type.micro(palette.textMuted)}>{label}</Text>
      </View>
    </Card>
  );
}

function AnimatedCard({ children }: { children: React.ReactNode }) {
  const Fade = require('react-native-reanimated').FadeInDown;
  const V = require('react-native-reanimated').default.View;
  return <V entering={Fade.springify().damping(18)} style={{ marginHorizontal: 20, marginTop: 16 }}>{children}</V>;
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  headerRow: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, gap: 12 },
  editBtn: { width: 42, height: 42, borderRadius: 21, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  profileRow: { flexDirection: 'row', alignItems: 'center' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  statRow: { flexDirection: 'row', gap: 12, paddingHorizontal: 20, marginTop: 14 },
  statIcon: { width: 30, height: 30, alignItems: 'center', justifyContent: 'center' },
  sectionTitle: { paddingHorizontal: 20, marginTop: 26, marginBottom: 12 },
  actionRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10 },
  pendingWrap: { justifyContent: 'center', alignItems: 'center', padding: 28 },
  pendingIcon: { width: 84, height: 84, borderRadius: 42, alignItems: 'center', justifyContent: 'center' },
  pendingBody: { textAlign: 'center', marginTop: 10, maxWidth: 300 },
});
