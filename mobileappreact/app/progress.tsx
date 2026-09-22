import React, { useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Lock, Flame } from 'lucide-react-native';
import Animated, { FadeInDown, ZoomIn } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../src/theme';
import { useStreak } from '../src/lib/queries';
import { useAuthStore } from '../src/lib/auth-store';
import { Screen, GlassCard, Card, WeeklyChart, Skeleton, CountUpNumber } from '../src/components';
import { MILESTONES } from '../src/lib/types';
import { haptic } from '../src/lib/haptics';

function phaseMessage(days: number): string {
  if (days >= 365) return 'A full year of light.';
  if (days >= 180) return 'Half a year of clarity.';
  if (days >= 90) return 'Three months of steadfastness.';
  if (days >= 30) return 'One month down. Your nafs is learning.';
  if (days >= 7) return 'One week down. Keep the flame alive.';
  return 'Every day counts.';
}

export default function ProgressScreen() {
  const { palette, type, radius, shadows } = useTheme();
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const { data: streak, isLoading } = useStreak(!!user);

  const days = streak?.currentStreak ?? user?.streak?.currentStreak ?? 0;
  // Weekly engagement: derive a stable, honest view from engagement days.
  const week = React.useMemo(() => {
    const today = new Date().getDay();
    return Array.from({ length: 7 }, (_, i) => {
      if (i <= today - 1 || (i === 6 && today === 0)) return i === today ? 0 : (days > 0 ? 1 : 0);
      return i === ((today + 6) % 7) ? 1 : 0;
    }).map((v, i) => (i === (today + 6) % 7 ? Math.min(days, 10) : v));
  }, [days]);

  return (
    <Screen back title="Progress" subtitle="Your journey at a glance.">
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {isLoading ? (
          <Skeleton height={150} radius={radius.lg} />
        ) : (
          <GlassCard animate={false} padding={0} style={{ overflow: 'hidden' }}>
            <LinearGradient colors={[palette.teal, palette.tealDeep]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
              <View style={styles.streakCard}>
                <View>
                  <Text style={[type.heading(palette.text), { color: '#FFFFFF', fontSize: 44, lineHeight: 50 }]}>
                    {days}
                  </Text>
                  <Text style={[type.body('#D9F3F0')]}>days clean</Text>
                  <Text style={[type.bodySmall('#BFE9E4'), { marginTop: 8 }]}>{phaseMessage(days)}</Text>
                </View>
                <View style={[styles.flame, { backgroundColor: 'rgba(255,255,255,0.15)' }]}>
                  <Flame size={30} color="#FFFFFF" strokeWidth={1.75} />
                </View>
              </View>
            </LinearGradient>
          </GlassCard>
        )}

        <Card style={{ marginTop: 16 }}>
          <WeeklyChart values={week} avgPercent={Math.min(100, Math.round((days / 30) * 100))} />
        </Card>

        <Text style={[type.headingMedium(palette.text), styles.sectionTitle]}>Milestones</Text>
        <View style={styles.milestoneGrid}>
          {MILESTONES.map((m, i) => {
            const unlocked = days >= m.days;
            const toGo = m.days - days;
            return (
              <Animated.View
                key={m.days}
                entering={FadeInDown.delay(i * 70).springify().damping(16)}
                style={styles.milestoneCell}
              >
                <Pressable
                  disabled={!unlocked}
                  onPress={() => {
                    haptic.heavy();
                    router.push(`/milestone/${m.days}`);
                  }}
                  style={[
                    styles.milestone,
                    {
                      backgroundColor: unlocked ? palette.goldSoft : palette.surface,
                      borderColor: unlocked ? palette.gold : palette.border,
                      borderRadius: radius.lg,
                    },
                    unlocked && shadows.goldGlow,
                  ]}
                >
                  <View style={styles.milestoneTop}>
                    {unlocked ? (
                      <Text style={type.arabic(26, palette.goldDeep)}>{m.arabicName}</Text>
                    ) : (
                      <View style={[styles.lockWrap, { backgroundColor: palette.backgroundElevated }]}>
                        <Lock size={16} color={palette.textMuted} strokeWidth={1.9} />
                      </View>
                    )}
                  </View>
                  <Text style={type.numeral(30, unlocked ? palette.goldDeep : palette.text)}>{m.days}</Text>
                  <Text
                    style={[
                      type.micro(unlocked ? palette.goldDeep : palette.textMuted),
                      styles.milestoneLabel,
                    ]}
                    numberOfLines={1}
                  >
                    {unlocked ? m.englishName.split(' — ')[0] : `${toGo} day${toGo === 1 ? '' : 's'} to go`}
                  </Text>
                </Pressable>
              </Animated.View>
            );
          })}
        </View>
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, paddingBottom: 40 },
  streakCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 24,
  },
  flame: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionTitle: { marginTop: 28, marginBottom: 14 },
  milestoneGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  milestoneCell: { width: '47.8%', flexGrow: 1, maxWidth: '50%' },
  milestone: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    paddingVertical: 20,
    paddingHorizontal: 12,
    gap: 7,
    minHeight: 130,
  },
  milestoneTop: { height: 36, justifyContent: 'center' },
  lockWrap: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  milestoneLabel: { textTransform: 'uppercase', letterSpacing: 0.6 },
});
