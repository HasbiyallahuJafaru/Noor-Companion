import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTheme } from '../../src/theme';
import { AuroraBackground } from '../../src/components/core/AuroraBackground';
import { Button, PressableScale, SelectableCard } from '../../src/components';
import { OnboardingProgress, OnboardingHeading } from '../../src/components/shared/OnboardingParts';

const OPTIONS = [
  { id: 'alcohol', title: 'Alcohol', subtitle: 'Finding freedom from drinking' },
  { id: 'drugs', title: 'Drugs', subtitle: 'Breaking the cycle' },
  { id: 'prescription', title: 'Prescription medication', subtitle: 'Rebuilding healthy patterns' },
  { id: 'private', title: 'Prefer not to say', subtitle: 'Your journey is your own' },
];

export default function OnboardingAddiction() {
  const { palette } = useTheme();
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AuroraBackground />
      <OnboardingProgress step={1} />
      <ScrollView contentContainerStyle={styles.scroll} bounces={false} showsVerticalScrollIndicator={false}>
        <OnboardingHeading title="What are you working through?" subtitle="This shapes the support Noor offers you. You can change this later." />
        <View style={styles.options}>
          {OPTIONS.map((o, i) => (
            <SelectableCard
              key={o.id}
              index={i}
              title={o.title}
              subtitle={o.subtitle}
              selected={selected === o.id}
              onPress={() => setSelected(o.id)}
            />
          ))}
        </View>
      </ScrollView>
      <View style={styles.footer}>
        <PressableScale haptic="light" onPress={() => router.push('/onboarding/stage')}>
          <Text style={[styles.skip, { color: palette.textMuted }]}>Skip for now</Text>
        </PressableScale>
        <Button
          label="Continue"
          onPress={() => router.push('/onboarding/stage')}
          disabled={!selected}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, paddingBottom: 24 },
  options: { paddingHorizontal: 24, marginTop: 24, gap: 12 },
  footer: { paddingHorizontal: 24, paddingBottom: 28, gap: 14, alignItems: 'center' },
  skip: { fontSize: 14, fontWeight: '600' },
});
