import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Star, Lock, Phone, Briefcase, Languages, GraduationCap } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { useTherapist } from '../../src/lib/queries';
import { useAuthStore } from '../../src/lib/auth-store';
import { api } from '../../src/lib/api';
import { Screen, GlassCard, Card, Button, Skeleton, ErrorState, Avatar, Chip } from '../../src/components';
import { formatNgnShort } from '../../src/lib/format';

export default function TherapistDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { palette, type, radius } = useTheme();
  const user = useAuthStore((s) => s.user);
  const { data: t, isLoading, isError, refetch } = useTherapist(String(id));
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (isLoading) {
    return (
      <Screen back>
        <View style={styles.skeletons}>
          <Skeleton height={90} radius={radius.lg} />
          <Skeleton height={140} radius={radius.lg} />
        </View>
      </Screen>
    );
  }
  if (isError || !t) {
    return (
      <Screen back>
        <ErrorState onRetry={() => refetch()} />
      </Screen>
    );
  }

  const isPaid = user?.subscriptionTier === 'paid';

  const startCall = async () => {
    setError(null);
    setStarting(true);
    try {
      const res = await api.callToken(t.id);
      router.push({
        pathname: `/call/${res.sessionId}`,
        params: {
          channelName: res.channelName,
          agoraToken: res.agoraToken,
          therapistName: `${t.firstName} ${t.lastName}`,
          therapistId: t.id,
        },
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not start the call');
    } finally {
      setStarting(false);
    }
  };

  return (
    <Screen back title={`${t.firstName} ${t.lastName}`} bottom={
      isPaid ? (
        <Button label={starting ? 'Connecting…' : 'Start Call'} icon={<Phone size={17} color="#FFFFFF" strokeWidth={2} />} onPress={startCall} loading={starting} />
      ) : (
        <Button label="Upgrade to Call" variant="gold" icon={<Lock size={17} color={palette.isDark ? '#241703' : '#FFFFFF'} strokeWidth={2.2} />} onPress={() => router.push('/upgrade')} />
      )
    }>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <GlassCard animate={false} padding={20}>
          <View style={styles.heroRow}>
            <Avatar url={t.avatarUrl} firstName={t.firstName} lastName={t.lastName} size={72} />
            <View style={{ flex: 1, marginLeft: 16 }}>
              <Text style={type.headingSmall(palette.text)}>
                {t.firstName} {t.lastName}
              </Text>
              <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 2 }]}>
                {t.yearsExperience} years experience
              </Text>
              <View style={styles.statRow}>
                <View style={[styles.stat, { backgroundColor: palette.goldSoft }]}>
                  <Star size={12} color={palette.gold} fill={palette.gold} strokeWidth={0} />
                  <Text style={[type.micro(palette.goldDeep), { marginLeft: 4 }]}>
                    {t.averageRating ? t.averageRating.toFixed(1) : 'New'}
                  </Text>
                </View>
                <View style={[styles.stat, { backgroundColor: palette.tealSoft }]}>
                  <Text style={type.micro(palette.tealDeep)}>{t.totalSessions} sessions</Text>
                </View>
              </View>
            </View>
          </View>
        </GlassCard>

        <Card style={styles.section}>
          <Text style={type.headingSmall(palette.text)}>About</Text>
          <Text style={[type.body(palette.textBody), { marginTop: 8 }]}>{t.bio}</Text>
        </Card>

        {t.specialisations?.length > 0 && (
          <Card style={styles.section}>
            <View style={styles.labelRow}>
              <Briefcase size={15} color={palette.teal} strokeWidth={2} />
              <Text style={[type.headingSmall(palette.text), { marginLeft: 8 }]}>Specialisations</Text>
            </View>
            <View style={styles.tagWrap}>
              {t.specialisations.map((s) => (
                <Chip key={s} label={s} />
              ))}
            </View>
          </Card>
        )}

        {t.qualifications?.length > 0 && (
          <Card style={styles.section}>
            <View style={styles.labelRow}>
              <GraduationCap size={15} color={palette.gold} strokeWidth={2} />
              <Text style={[type.headingSmall(palette.text), { marginLeft: 8 }]}>Qualifications</Text>
            </View>
            <View style={{ marginTop: 10, gap: 8 }}>
              {t.qualifications.map((q) => (
                <Text key={q} style={type.bodySmall(palette.textBody)}>
                  •  {q}
                </Text>
              ))}
            </View>
          </Card>
        )}

        {t.languagesSpoken?.length > 0 && (
          <Card style={styles.section}>
            <View style={styles.labelRow}>
              <Languages size={15} color={palette.purple} strokeWidth={2} />
              <Text style={[type.headingSmall(palette.text), { marginLeft: 8 }]}>Languages</Text>
            </View>
            <View style={[styles.tagWrap, { marginTop: 12 }]}>
              {t.languagesSpoken.map((l) => (
                <Chip key={l} label={l} color="gold" />
              ))}
            </View>
          </Card>
        )}

        <GlassCard animate={false} padding={18} style={[styles.section, { backgroundColor: palette.tealTint }]}>
          <View style={styles.priceRow}>
            <Text style={type.body(palette.textSecondary)}>Session rate</Text>
            <Text style={type.headingMedium(palette.tealDeep)}>
              {formatNgnShort(t.sessionRateNgn)} per session
            </Text>
          </View>
        </GlassCard>

        {error && (
          <View style={[styles.error, { backgroundColor: palette.dangerSoft, borderRadius: radius.md }]}>
            <Text style={type.bodySmall(palette.danger)}>{error}</Text>
          </View>
        )}
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  skeletons: { padding: 20, gap: 14 },
  scroll: { padding: 20, paddingBottom: 40 },
  heroRow: { flexDirection: 'row', alignItems: 'center' },
  statRow: { flexDirection: 'row', gap: 8, marginTop: 10 },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 999,
  },
  section: { marginTop: 14 },
  labelRow: { flexDirection: 'row', alignItems: 'center' },
  tagWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  priceRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  error: { padding: 12, marginTop: 14 },
});
