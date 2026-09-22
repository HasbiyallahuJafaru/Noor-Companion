import React, { useState } from 'react';
import { View, Text, StyleSheet, FlatList, Alert, TextInput, ScrollView } from 'react-native';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { ChevronLeft, Check, X } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { Card, Avatar, Badge, Button, Skeleton, EmptyState, ErrorState, PressableScale, Input } from '../../src/components';
import { relativeTime, formatNgnShort } from '../../src/lib/format';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';
import { haptic } from '../../src/lib/haptics';
import type { PendingTherapist } from '../../src/lib/types';

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

export default function AdminTherapists() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const qc = useQueryClient();
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-pending-therapists'],
    queryFn: () => api.adminPendingTherapists(),
  });
  const [busyId, setBusyId] = useState<string | null>(null);

  const items = data ?? [];

  const approve = (t: PendingTherapist) => {
    Alert.alert(
      'Approve application',
      `${t.firstName} ${t.lastName} will become an active therapist on the platform.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Approve',
          onPress: async () => {
            setBusyId(t.id);
            try {
              await api.adminApproveTherapist(t.id);
              haptic.success();
              qc.invalidateQueries({ queryKey: ['admin-pending-therapists'] });
            } finally {
              setBusyId(null);
            }
          },
        },
      ],
    );
  };

  const reject = (t: PendingTherapist) => {
    Alert.alert(
      'Reject application',
      'Provide a brief reason (shared with the applicant):',
      [
        { text: 'Cancel', style: 'cancel' },
      ],
    );
    // Full reason sheet rendered below via state
    setRejecting(t);
  };

  const [rejecting, setRejecting] = useState<PendingTherapist | null>(null);
  const [reason, setReason] = useState('');
  const [rejectError, setRejectError] = useState<string | null>(null);

  const confirmReject = async () => {
    if (!rejecting) return;
    if (reason.trim().length < 5) {
      setRejectError('Reason must be at least 5 characters.');
      return;
    }
    setBusyId(rejecting.id);
    try {
      await api.adminRejectTherapist(rejecting.id, reason.trim());
      haptic.medium();
      setRejecting(null);
      setReason('');
      qc.invalidateQueries({ queryKey: ['admin-pending-therapists'] });
    } finally {
      setBusyId(null);
    }
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AURORA />
      <View style={styles.header}>
        <PressableScale haptic="light" pressScale={0.9} onPress={() => router.back()} style={[styles.back, { backgroundColor: palette.surface, borderColor: palette.border }]}>
          <ChevronLeft size={22} color={palette.text} strokeWidth={2.2} />
        </PressableScale>
        <Text style={type.headingMedium(palette.text)}>Pending Therapists</Text>
        <View style={{ width: 42 }} />
      </View>

      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1].map((i) => (
            <Skeleton key={i} height={170} radius={radius.lg} />
          ))}
        </View>
      ) : isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : items.length === 0 ? (
        <EmptyState
          title="Queue is clear"
          body="Every application has been reviewed. New applications will appear here."
        />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(t) => t.id}
          contentContainerStyle={{ padding: 20, gap: 14 }}
          renderItem={({ item, index }) => (
            <Animated.View entering={enterList(index)}>
              <Card padding={18}>
                <View style={styles.cardTop}>
                  <Avatar firstName={item.firstName} lastName={item.lastName} size={48} />
                  <View style={{ flex: 1, marginLeft: 12 }}>
                    <Text style={type.headingSmall(palette.text)}>
                      {item.firstName} {item.lastName}
                    </Text>
                    <Text style={[type.caption(palette.textMuted), { marginTop: 2 }]}>
                      {item.yearsExperience} yrs exp · {formatNgnShort(item.sessionRateNgn)}/session · {relativeTime(item.createdAt)}
                    </Text>
                  </View>
                </View>
                <Text style={[type.bodySmall(palette.textBody), styles.bio]} numberOfLines={3}>
                  {item.bio}
                </Text>
                <View style={styles.chipRow}>
                  {item.specialisations.slice(0, 3).map((s) => (
                    <Badge key={s} label={s} color="teal" />
                  ))}
                  {item.qualifications.slice(0, 2).map((q) => (
                    <Badge key={q} label={q} color="gold" />
                  ))}
                </View>
                <View style={styles.actions}>
                  <PressableScale haptic="heavy" style={{ flex: 1 }} onPress={() => reject(item)}>
                    <View style={[styles.rejectBtn, { borderColor: palette.danger, borderRadius: radius.pill }]}>
                      <X size={16} color={palette.danger} strokeWidth={2.4} />
                      <Text style={[type.button(palette.danger), { marginLeft: 6, fontSize: 13.5 }]}>Reject</Text>
                    </View>
                  </PressableScale>
                  <PressableScale haptic="heavy" style={{ flex: 1 }} onPress={() => approve(item)} disabled={busyId === item.id}>
                    <View style={[styles.approveBtn, { backgroundColor: palette.teal, borderRadius: radius.pill }]}>
                      <Check size={16} color="#FFFFFF" strokeWidth={2.6} />
                      <Text style={[type.button('#FFFFFF'), { marginLeft: 6, fontSize: 13.5 }]}>
                        {busyId === item.id ? '…' : 'Approve'}
                      </Text>
                    </View>
                  </PressableScale>
                </View>
              </Card>
            </Animated.View>
          )}
        />
      )}

      {/* Rejection reason sheet */}
      {rejecting && (
        <View style={[styles.sheet, { backgroundColor: palette.overlay }]}>
          <View style={[styles.sheetCard, { backgroundColor: palette.surface, borderRadius: radius.xl }]}>
            <Text style={type.headingSmall(palette.text)}>Reject application</Text>
            <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 6 }]}>
              Reason for rejecting {rejecting.firstName} {rejecting.lastName}:
            </Text>
            <View style={{ marginTop: 14 }}>
              <Input label="Reason" placeholder="Minimum 5 characters" value={reason} onChangeText={setReason} multiline />
            </View>
            {rejectError && <Text style={[type.bodySmall(palette.danger), { marginTop: 8 }]}>{rejectError}</Text>}
            <View style={styles.sheetActions}>
              <Button label="Cancel" variant="ghost" onPress={() => setRejecting(null)} />
              <Button label="Confirm Reject" variant="danger" onPress={confirmReject} />
            </View>
          </View>
        </View>
      )}
    </View>
  );
}

const ABS_FILL = { position: 'absolute' as const, top: 0, left: 0, right: 0, bottom: 0 };

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
  skeletons: { padding: 20, gap: 14 },
  cardTop: { flexDirection: 'row', alignItems: 'center' },
  bio: { marginTop: 12 },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 12 },
  actions: { flexDirection: 'row', gap: 12, marginTop: 18 },
  rejectBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    paddingVertical: 12,
  },
  approveBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
  },
  sheet: { ...ABS_FILL, alignItems: 'center', justifyContent: 'center', padding: 28, zIndex: 40 },
  sheetCard: { width: '100%', padding: 22 },
  sheetActions: { flexDirection: 'row', gap: 10, marginTop: 18 },
});
