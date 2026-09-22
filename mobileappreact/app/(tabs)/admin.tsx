import React from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Users, UserCheck, CreditCard, Stethoscope, Hourglass, PhoneCall, ChevronRight, RefreshCw, ShieldCheck } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { Card, GlassCard, Skeleton, ErrorState, PressableScale } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

export default function AdminDashboard() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const { data, isLoading, isError, refetch, isRefetching } = useQuery({
    queryKey: ['admin-analytics'],
    queryFn: () => api.adminAnalytics(),
  });

  const tiles = data
    ? [
        { icon: Users, label: 'Total Users', value: data.totalUsers, tint: palette.teal, tintBg: palette.tealSoft },
        { icon: UserCheck, label: 'Active Today', value: data.activeToday, tint: palette.orange, tintBg: `${palette.orange}22` },
        { icon: CreditCard, label: 'Paid Subscribers', value: data.paidSubscribers, tint: palette.gold, tintBg: palette.goldSoft },
        { icon: Stethoscope, label: 'Therapists', value: data.totalTherapists, tint: palette.success, tintBg: palette.successSoft },
        { icon: Hourglass, label: 'Pending Review', value: data.pendingTherapists, tint: palette.danger, tintBg: palette.dangerSoft },
        { icon: PhoneCall, label: 'Calls This Month', value: data.callSessionsThisMonth, tint: palette.purple, tintBg: palette.purpleSoft },
      ]
    : [];

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <ScrollView contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: 140 }} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <View style={{ flex: 1 }}>
            <Text style={type.heading(palette.text)}>Admin Panel</Text>
            <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 2 }]}>Platform management</Text>
          </View>
          <PressableScale haptic="light" onPress={() => refetch()} style={[styles.refresh, { backgroundColor: palette.surface, borderColor: palette.border }]}>
            <RefreshCw size={18} color={isRefetching ? palette.teal : palette.textSecondary} strokeWidth={2} />
          </PressableScale>
        </View>

        {isLoading ? (
          <View style={styles.grid}>
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} width={'47.5%'} height={104} radius={radius.lg} />
            ))}
          </View>
        ) : isError ? (
          <ErrorState onRetry={() => refetch()} />
        ) : (
          <View style={styles.grid}>
            {tiles.map((t, i) => (
              <Animated.View key={t.label} entering={enterList(i)} style={{ width: '47.5%', flexGrow: 1 }}>
                <Card padding={16} style={{ height: 104, justifyContent: 'space-between' }}>
                  <View style={[styles.tileIcon, { backgroundColor: t.tintBg, borderRadius: radius.sm }]}>
                    <t.icon size={17} color={t.tint} strokeWidth={1.9} />
                  </View>
                  <View>
                    <Text style={type.headingSmall(palette.text)}>{t.value.toLocaleString()}</Text>
                    <Text style={type.micro(palette.textMuted)}>{t.label}</Text>
                  </View>
                </Card>
              </Animated.View>
            ))}
          </View>
        )}

        <Text style={[type.headingMedium(palette.text), styles.sectionTitle]}>Management</Text>
        <GlassCard animate={false} padding={6}>
          <ManagementRow icon={Users} tint={palette.teal} label="Users" sub="Roles, tiers, suspension" onPress={() => router.push('/admin/users')} />
          <ManagementRow icon={Hourglass} tint={palette.gold} label="Therapists" sub="Approve or reject applications" onPress={() => router.push('/admin/therapists')} />
          <ManagementRow icon={ShieldCheck} tint={palette.purple} label="Content" sub="Dhikr, duas and recitations" onPress={() => router.push('/admin/content')} />
          <ManagementRow icon={PhoneCall} tint={palette.success} label="Broadcast" sub="Send a platform notification" onPress={() => router.push('/admin/broadcast')} last />
        </GlassCard>
      </ScrollView>
    </View>
  );
}

function ManagementRow({
  icon: Icon,
  tint,
  label,
  sub,
  onPress,
  last,
}: {
  icon: typeof Users;
  tint: string;
  label: string;
  sub: string;
  onPress: () => void;
  last?: boolean;
}) {
  const { palette, type, radius } = useTheme();
  return (
    <PressableScale haptic="light" onPress={onPress}>
      <View style={[styles.row, !last && { borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: palette.hairline }]}>
        <View style={[styles.rowIcon, { backgroundColor: `${tint}1A`, borderRadius: radius.sm }]}>
          <Icon size={18} color={tint} strokeWidth={1.9} />
        </View>
        <View style={{ flex: 1, marginLeft: 14 }}>
          <Text style={type.headingSmall(palette.text)}>{label}</Text>
          <Text style={[type.micro(palette.textMuted), { marginTop: 2 }]}>{sub}</Text>
        </View>
        <ChevronRight size={18} color={palette.textMuted} strokeWidth={2} />
      </View>
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, gap: 12 },
  refresh: { width: 42, height: 42, borderRadius: 21, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12, paddingHorizontal: 20, marginTop: 20 },
  tileIcon: { width: 32, height: 32, alignItems: 'center', justifyContent: 'center' },
  sectionTitle: { paddingHorizontal: 20, marginTop: 28, marginBottom: 12 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 14,
  },
  rowIcon: { width: 38, height: 38, alignItems: 'center', justifyContent: 'center' },
});
