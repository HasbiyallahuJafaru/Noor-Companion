import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { ChevronRight, Clock, MapPinOff, BookOpen, HandHeart, Flame, Sparkles, Bell, Heart } from 'lucide-react-native';
import Animated, {
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
  useAnimatedStyle,
} from 'react-native-reanimated';
import { useTheme } from '../../src/theme';
import { useAuthStore } from '../../src/lib/auth-store';
import { useDhikr, useStreak, useNotifications } from '../../src/lib/queries';
import { usePrayerTimes, useNextPrayer } from '../../src/lib/prayer';
import { greeting, timeTag } from '../../src/lib/format';
import { GlassCard, Skeleton, StreakRing, PressableScale, MoodFace } from '../../src/components';
import { MOOD_SCALE } from '../../src/components/core/MoodFace';
import { haptic } from '../../src/lib/haptics';
import { enterList } from '../../src/theme/motion';
import type { PrayerTimesModel } from '../../src/lib/types';

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

/** Card artwork. Each is dark and low-contrast so the label reads over it. */
const CARD_ART = {
  dhikr: require('../../assets/cards/dhikr.jpg'),
  quran: require('../../assets/cards/quran.jpg'),
  duas: require('../../assets/cards/duas.jpg'),
};

export default function HomeScreen() {
  const { palette, type, radius, shadows } = useTheme();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((s) => s.user);

  const { data: streakData } = useStreak(!!user);
  const { data: dhikr, isLoading: dhikrLoading } = useDhikr();
  const { data: notif } = useNotifications(!!user);
  const prayer = usePrayerTimes(!!user);

  const prayerData: PrayerTimesModel | null =
    prayer.status.state === 'ready' ? prayer.status.data : null;
  const nextPrayer = useNextPrayer(prayerData);

  const [mood, setMood] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const days = streakData?.currentStreak ?? user?.streak?.currentStreak ?? 0;
  const milestone = [7, 14, 30, 100].includes(days);
  const firstName = user?.firstName ?? '';
  const tag = timeTag();

  const featured = dhikr?.find((d) => d.tags.includes(tag)) ?? dhikr?.[0];
  const railTag = tag === 'evening' ? 'evening' : 'morning';
  const railItems = (dhikr ?? []).filter((d) => d.tags.includes(railTag)).slice(0, 6);

  const onRefresh = () => {
    setRefreshing(true);
    prayer.reload();
    setTimeout(() => setRefreshing(false), 600);
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingTop: insets.top + 14, paddingBottom: insets.bottom + 150 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={palette.teal} />}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={{ flex: 1 }}>
            <Text style={type.heading(palette.text)}>
              {greeting()}
              {firstName ? `, ${firstName}` : ''}
            </Text>
            <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 3 }]}>How are you feeling today?</Text>
          </View>
          <PressableScale
            haptic="light"
            pressScale={0.9}
            onPress={() => router.push('/notifications')}
            style={[styles.bell, { backgroundColor: palette.surface, borderColor: palette.border }, shadows.sm]}
          >
            <Bell size={20} color={palette.text} strokeWidth={1.9} />
            {(notif?.unreadCount ?? 0) > 0 && <View style={[styles.bellDot, { backgroundColor: palette.danger }]} />}
          </PressableScale>
        </View>

        {/* Prayer banner */}
        <Animated.View entering={enterList(0)} style={{ paddingHorizontal: 20, marginTop: 18 }}>
          {prayer.status.state === 'ready' && prayerData ? (
            <View
              style={[
                styles.prayerBanner,
                { backgroundColor: palette.tealSoft, borderRadius: radius.pill, borderColor: palette.border },
              ]}
            >
              <Clock size={17} color={palette.tealDeep} strokeWidth={2} />
              <Text style={[type.caption(palette.tealDeep), styles.prayerName]}>Next: {nextPrayer.name}</Text>
              <View style={{ flex: 1 }} />
              <Text style={type.figure(14, palette.tealDeep)}>{nextPrayer.countdown}</Text>
            </View>
          ) : prayer.status.state === 'denied' ? (
            <PressableScale haptic="light" onPress={prayer.reload}>
              <View
                style={[
                  styles.prayerBanner,
                  { backgroundColor: palette.backgroundElevated, borderRadius: radius.pill, borderColor: palette.border },
                ]}
              >
                <MapPinOff size={17} color={palette.textMuted} strokeWidth={2} />
                <Text style={[type.bodySmall(palette.textSecondary), { flex: 1 }]}>Prayer times need location access</Text>
                <Text style={type.title(palette.teal)}>Enable</Text>
              </View>
            </PressableScale>
          ) : (
            <Skeleton height={48} radius={24} />
          )}
        </Animated.View>

        {/* Mood */}
        <Animated.View entering={enterList(1)} style={styles.moodRow}>
          {MOOD_SCALE.map((m) => {
            const selected = mood === m.label;
            return (
              <Pressable
                key={m.label}
                accessibilityRole="button"
                accessibilityLabel={`Feeling ${m.label.toLowerCase()}`}
                accessibilityState={{ selected }}
                onPress={() => {
                  haptic.light();
                  setMood(m.label);
                }}
                style={[
                  styles.moodCell,
                  {
                    backgroundColor: selected ? `${palette.teal}1F` : palette.surface,
                    borderColor: selected ? palette.teal : palette.border,
                  },
                  shadows.sm,
                ]}
              >
                <MoodFace
                  mood={m.mood}
                  size={24}
                  color={selected ? palette.teal : palette.textMuted}
                  strokeWidth={selected ? 1.9 : 1.6}
                />
                <Text style={type.micro(selected ? palette.teal : palette.textMuted)}>{m.label}</Text>
              </Pressable>
            );
          })}
        </Animated.View>

        {/* Streak */}
        <Animated.View entering={enterList(2)} style={{ paddingHorizontal: 20, marginTop: 24 }}>
          <PressableScale haptic="light" onPress={() => router.push('/progress')}>
            <GlassCard
              padding={22}
              style={[
                milestone && {
                  shadowColor: palette.gold,
                  shadowOpacity: 0.35,
                  shadowRadius: 24,
                  shadowOffset: { width: 0, height: 8 },
                },
              ]}
            >
              <View style={styles.streakRow}>
                <StreakRing days={days} milestone={milestone} />
                <View style={{ flex: 1, paddingLeft: 20 }}>
                  <Text style={type.headingMedium(palette.text)}>
                    {milestone ? 'Milestone reached' : 'days of clarity'}
                  </Text>
                  <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 6 }]}>
                    {milestone
                      ? 'Your consistency is showing. Keep going.'
                      : days === 0
                        ? 'Complete a dhikr to begin your streak.'
                        : 'Each day, another brick in the wall.'}
                  </Text>
                  <View style={[styles.streakMeta, { marginTop: 12 }]}>
                    <Flame size={14} color={palette.gold} strokeWidth={2} />
                    <Text style={[type.caption(palette.textSecondary), { marginLeft: 6 }]}>
                      Best: {streakData?.longestStreak ?? user?.streak?.longestStreak ?? days} days
                    </Text>
                  </View>
                </View>
              </View>
            </GlassCard>
          </PressableScale>
        </Animated.View>

        {/* Daily Dhikr */}
        <View style={[styles.sectionHeader, { marginTop: 28 }]}>
          <Text style={type.headingMedium(palette.text)}>Daily Dhikr</Text>
          <View style={[styles.tagChip, { backgroundColor: palette.tealSoft }]}>
            <Sparkles size={12} color={palette.tealDeep} strokeWidth={2} />
            <Text style={[type.micro(palette.tealDeep), { marginLeft: 5 }]}>
              {tag === 'morning' ? 'Morning' : tag === 'evening' ? 'Evening' : 'Today'}
            </Text>
          </View>
        </View>
        <Animated.View entering={enterList(3)} style={{ paddingHorizontal: 20 }}>
          {dhikrLoading ? (
            <Skeleton height={150} radius={radius.lg} />
          ) : featured ? (
            <PressableScale haptic="medium" onPress={() => router.push(`/dhikr/${featured.id}`)}>
              <GlassCard
                animate={false}
                padding={20}
                style={{ marginTop: 12 }}
                image={CARD_ART.dhikr}
                imageAnchor="full"
              >
                <Text style={[type.arabic(21, '#F6F3EC'), styles.arabicClamp]} numberOfLines={2}>
                  {featured.arabicText}
                </Text>
                <Text style={[type.quote(14, 'rgba(246,243,236,0.82)'), styles.translationClamp]} numberOfLines={2}>
                  {featured.translation}
                </Text>
                <View style={styles.featuredFooter}>
                  <View style={[styles.countPill, styles.countPillOnArt]}>
                    <Text style={type.caption('#F6F3EC')}>
                      {featured.targetCount}x · {featured.title}
                    </Text>
                  </View>
                  <View style={{ flex: 1 }} />
                  <ChevronRight size={18} color="rgba(246,243,236,0.7)" strokeWidth={2} />
                </View>
              </GlassCard>
            </PressableScale>
          ) : null}
        </Animated.View>

        {/* Adhkar rail */}
        {railItems.length > 0 && (
          <>
            <View style={[styles.sectionHeader, { marginTop: 28 }]}>
              <Text style={type.headingMedium(palette.text)}>
                {railTag === 'morning' ? 'Morning Adhkar' : 'Evening Adhkar'}
              </Text>
            </View>
            <Animated.View entering={enterList(4)}>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.rail}>
                {railItems.map((d, i) => (
                  <PressableScale key={d.id} haptic="light" onPress={() => router.push(`/dhikr/${d.id}`)}>
                    <GlassCard index={i} padding={16} style={{ width: 150, height: 118, justifyContent: 'space-between' }}>
                      <Text style={type.arabic(15, palette.text)} numberOfLines={2}>
                        {d.arabicText}
                      </Text>
                      <View>
                        <Text style={type.micro(palette.textMuted)} numberOfLines={1}>
                          {d.title}
                        </Text>
                        <Text style={[type.caption(palette.teal), { marginTop: 2 }]}>{d.targetCount}x</Text>
                      </View>
                    </GlassCard>
                  </PressableScale>
                ))}
              </ScrollView>
            </Animated.View>
          </>
        )}

        {/* Explore */}
        <View style={[styles.sectionHeader, { marginTop: 28 }]}>
          <Text style={type.headingMedium(palette.text)}>Explore</Text>
        </View>
        <View style={styles.exploreRow}>
          <PressableScale haptic="medium" onPress={() => router.push('/(tabs)/quran')} style={{ flex: 1 }}>
            <GlassCard
              index={5}
              padding={18}
              style={styles.exploreCard}
              image={CARD_ART.quran}
            >
              <View style={[styles.exploreIcon, styles.exploreIconOnArt]}>
                <BookOpen size={20} color="#F6F3EC" strokeWidth={1.75} />
              </View>
              <View>
                <Text style={type.titleSerif('#F6F3EC')}>Quran</Text>
                <Text style={type.micro('rgba(246,243,236,0.72)')}>114 surahs</Text>
              </View>
            </GlassCard>
          </PressableScale>
          <PressableScale haptic="medium" onPress={() => router.push('/duas')} style={{ flex: 1 }}>
            <GlassCard
              index={6}
              padding={18}
              style={styles.exploreCard}
              image={CARD_ART.duas}
            >
              <View style={[styles.exploreIcon, styles.exploreIconOnArt]}>
                <HandHeart size={20} color="#F0B355" strokeWidth={1.75} />
              </View>
              <View>
                <Text style={type.titleSerif('#F6F3EC')}>Duas</Text>
                <Text style={type.micro('rgba(246,243,236,0.72)')}>Every occasion</Text>
              </View>
            </GlassCard>
          </PressableScale>
        </View>
      </ScrollView>

      {/* Panic button — pinned above the tab bar */}
      <View style={[styles.panicHost, { paddingHorizontal: 20, bottom: insets.bottom + 104 }]}>
        <PressableScale haptic="heavy" pressScale={0.985} onPress={() => router.push('/intervention/dua')}>
          <PanicButton />
        </PressableScale>
      </View>
    </View>
  );
}

/** Pulsing panic button: a slow 1.0 → 1.015 breathing loop. */
function PanicButton() {
  const { palette, type, radius, shadows } = useTheme();
  const scale = useSharedValue(1);
  React.useEffect(() => {
    scale.value = withRepeat(
      withSequence(withTiming(1.015, { duration: 1000 }), withTiming(1, { duration: 1000 })),
      -1,
    );
    return () => {
      scale.value = 1;
    };
  }, [scale]);
  const anim = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  return (
    <Animated.View
      style={[styles.panic, { backgroundColor: palette.teal, borderRadius: radius.md }, shadows.md, anim]}
    >
      <View style={styles.panicRow}>
        <Heart size={20} color="#FFFFFF" strokeWidth={2.2} />
        <Text style={type.title('#FFFFFF')}>I'm Struggling</Text>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    gap: 12,
  },
  bell: {
    width: 42,
    height: 42,
    borderRadius: 21,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellDot: {
    position: 'absolute',
    top: 9,
    right: 10,
    width: 9,
    height: 9,
    borderRadius: 5,
    borderWidth: 1.5,
    borderColor: '#FFFFFF',
  },
  prayerBanner: {
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 18,
    borderWidth: 1,
  },
  moodRow: {
    flexDirection: 'row',
    gap: 10,
    paddingHorizontal: 20,
    marginTop: 16,
  },
  moodCell: {
    flex: 1,
    alignItems: 'center',
    gap: 5,
    paddingVertical: 12,
    borderRadius: 14,
    borderWidth: 1.4,
  },
  prayerName: { letterSpacing: 0 },
  streakRow: { flexDirection: 'row', alignItems: 'center' },
  streakMeta: { flexDirection: 'row', alignItems: 'center' },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginBottom: 2,
  },
  tagChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 999,
  },
  arabicClamp: { textAlign: 'right', writingDirection: 'rtl' as const },
  translationClamp: { marginTop: 8 },
  featuredFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 16,
  },
  countPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
  },
  countPillOnArt: {
    backgroundColor: 'rgba(255,255,255,0.16)',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: 'rgba(255,255,255,0.22)',
  },
  exploreCard: { height: 130, justifyContent: 'space-between' },
  rail: { paddingHorizontal: 20, gap: 12, marginTop: 12 },
  exploreRow: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 20,
    marginTop: 12,
  },
  exploreIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  exploreIconOnArt: {
    backgroundColor: 'rgba(255,255,255,0.14)',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  panicHost: { position: 'absolute', left: 0, right: 0 },
  panic: { paddingVertical: 18, alignItems: 'center', justifyContent: 'center' },
  panicRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
});
