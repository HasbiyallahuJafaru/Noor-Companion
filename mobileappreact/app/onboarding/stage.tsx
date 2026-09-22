import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTheme } from '../../src/theme';
import { AppBackground } from '../../src/components/core/AppBackground';
import { Button, SelectableCard } from '../../src/components';
import { OnboardingProgress, OnboardingHeading } from '../../src/components/shared/OnboardingParts';

const STAGES = [
  { id: 'starting', title: 'Just starting', subtitle: 'Day one energy' },
  { id: 'weeks', title: 'A few weeks', subtitle: 'Momentum is building' },
  { id: 'months', title: 'A few months', subtitle: 'Deep into the journey' },
  { id: 'year', title: 'Over a year', subtitle: 'Long-term clarity' },
];

export default function OnboardingStage() {
  const { palette } = useTheme();
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AppBackground variant="sanctuary" />
      <OnboardingProgress step={2} />
      <ScrollView contentContainerStyle={styles.scroll} bounces={false} showsVerticalScrollIndicator={false}>
        <OnboardingHeading title="How long have you been on this journey?" subtitle="Milestones and encouragement are calibrated to where you are." />
        <View style={styles.options}>
          {STAGES.map((s, i) => (
            <SelectableCard
              key={s.id}
              index={i}
              title={s.title}
              subtitle={s.subtitle}
              selected={selected === s.id}
              onPress={() => setSelected(s.id)}
            />
          ))}
        </View>
      </ScrollView>
      <View style={styles.footer}>
        <Button label="Continue" onPress={() => router.push('/onboarding/therapist')} disabled={!selected} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, paddingBottom: 24 },
  options: { paddingHorizontal: 24, marginTop: 24, gap: 12 },
  footer: { paddingHorizontal: 24, paddingBottom: 28 },
});
