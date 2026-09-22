import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../src/theme';
import { useDhikr, useRecordProgress } from '../../src/lib/queries';
import { Screen, ArabicBlock, AudioBar, TasbihCounter, Button, Skeleton, ErrorState } from '../../src/components';
import { haptic } from '../../src/lib/haptics';
import { MILESTONES } from '../../src/lib/types';
import { Confetti } from '../../src/components/core/Confetti';

export default function DhikrDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { palette, type, radius } = useTheme();
  const { data, isLoading, isError, refetch } = useDhikr();
  const item = data?.find((d) => d.id === id);
  const record = useRecordProgress();

  const [count, setCount] = useState(0);
  const [doneMsg, setDoneMsg] = useState(false);
  const [milestoneDays, setMilestoneDays] = useState<number | null>(null);

  if (isLoading) {
    return (
      <Screen back title="Dhikr">
        <View style={{ padding: 20, gap: 16 }}>
          <Skeleton height={140} radius={radius.lg} />
          <Skeleton height={200} radius={radius.xl} />
        </View>
      </Screen>
    );
  }
  if (isError || !item) {
    return (
      <Screen back title="Dhikr">
        <ErrorState onRetry={() => refetch()} />
      </Screen>
    );
  }

  const complete = count >= item.targetCount;

  const onTap = () => {
    const next = count + 1;
    setCount(next);
    if (next === item.targetCount) haptic.success();
    else haptic.tap();
  };

  const markComplete = async () => {
    if (!complete || record.isPending) return;
    try {
      const res = await record.mutateAsync(item.id);
      const streak = res?.streak?.currentStreak;
      const hit = MILESTONES.find((m) => m.days === streak);
      setMilestoneDays(hit ? hit.days : null);
    } catch {
      // progress recording is best-effort; counter still completes
    }
    haptic.success();
    setDoneMsg(true);
  };

  return (
    <Screen back title={item.title} bottom={
      <Button
        label={doneMsg ? 'Recorded — Barakallahu feek' : 'Mark Complete'}
        onPress={markComplete}
        disabled={!complete || record.isPending || doneMsg}
        loading={record.isPending}
      />
    }>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <ArabicBlock
          animate={false}
          arabic={item.arabicText}
          transliteration={item.transliteration}
          translation={item.translation}
        />
        {item.audioUrl ? (
          <View style={{ marginTop: 14 }}>
            <AudioBar source={item.audioUrl} label="Recitation" />
          </View>
        ) : null}
        <View style={styles.counterWrap}>
          <TasbihCounter
            target={item.targetCount}
            count={count}
            onTap={onTap}
            onReset={() => setCount(0)}
          />
        </View>
        {doneMsg && <Confetti run />}
      </ScrollView>
      {milestoneDays !== null && (
        <MilestoneGate days={milestoneDays} onClose={() => setMilestoneDays(null)} />
      )}
    </Screen>
  );
}

function MilestoneGate({ days, onClose }: { days: number; onClose: () => void }) {
  const { palette, type, radius } = useTheme();
  const milestone = MILESTONES.find((m) => m.days === days);
  return (
    <View style={[styles.gate, { backgroundColor: palette.overlay }]}>
      <Confetti />
      <LinearGradient
        colors={[palette.isDark ? '#1B1F42' : '#171930', palette.isDark ? '#10122A' : '#232544']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={{ borderRadius: radius.xl }}
      >
        <View style={styles.gateCard}>
          <Text style={type.arabic(30, palette.gold)}>{milestone?.arabicName}</Text>
          <Text style={[type.heading(palette.text), { marginTop: 8, color: '#FFFFFF' }]}>
            {milestone?.englishName}
          </Text>
          <Text style={[type.headingSmall(palette.gold), { marginTop: 4 }]}>
            {days} days of clarity
          </Text>
          <Text style={[type.bodySmall('#C6C7DD'), { marginTop: 14, textAlign: 'center' }]}>
            {milestone?.translation}
          </Text>
          <Text style={[type.caption(palette.textMuted), { marginTop: 6 }]}>{milestone?.reference}</Text>
          <View style={{ marginTop: 22, alignSelf: 'stretch' }}>
            <Button label="Continue" onPress={onClose} />
          </View>
        </View>
      </LinearGradient>
    </View>
  );
}

const ABS_FILL = { position: 'absolute' as const, top: 0, left: 0, right: 0, bottom: 0 };

const styles = StyleSheet.create({
  scroll: { padding: 20, paddingBottom: 40 },
  counterWrap: { alignItems: 'center', marginTop: 28 },
  gate: {
    ...ABS_FILL,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 28,
    zIndex: 50,
  },
  gateCard: { padding: 28, alignItems: 'center' },
});
