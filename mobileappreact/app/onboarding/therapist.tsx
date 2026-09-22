import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { HeartHandshake, CalendarClock } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { AuroraBackground } from '../../src/components/core/AuroraBackground';
import { Button, SelectableCard, GlassCard } from '../../src/components';
import { useAuthStore } from '../../src/lib/auth-store';
import { OnboardingProgress, OnboardingHeading } from '../../src/components/shared/OnboardingParts';

export default function OnboardingTherapist() {
  const { palette, type } = useTheme();
  const [selected, setSelected] = useState<boolean | null>(null);
  const setOnboarded = useAuthStore((s) => s.setOnboarded);

  const finish = async () => {
    await setOnboarded(true);
    router.replace('/(tabs)');
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AuroraBackground />
      <OnboardingProgress step={3} />
      <ScrollView contentContainerStyle={styles.scroll} bounces={false} showsVerticalScrollIndicator={false}>
        <OnboardingHeading title="Would you like access to a therapist?" subtitle="Verified Muslim therapists are one call away, whenever you're ready." />
        <View style={styles.options}>
          <SelectableCard
            index={0}
            title="Yes, connect me"
            subtitle="Browse the directory and call when it suits you"
            selected={selected === true}
            onPress={() => setSelected(true)}
          />
          <SelectableCard
            index={1}
            title="Maybe later"
            subtitle="You can explore therapists any time"
            selected={selected === false}
            onPress={() => setSelected(false)}
          />
        </View>
        {selected !== null && (
          <GlassCard index={2} padding={18} style={{ marginHorizontal: 24, marginTop: 18 }}>
            <View style={styles.perkRow}>
              <HeartHandshake size={18} color={palette.teal} strokeWidth={1.75} />
              <Text style={[type.bodySmall(palette.textBody), styles.perkText]}>
                Paid members can start a voice session with any available therapist
              </Text>
            </View>
            <View style={styles.perkRow}>
              <CalendarClock size={18} color={palette.teal} strokeWidth={1.75} />
              <Text style={[type.bodySmall(palette.textBody), styles.perkText]}>
                Every session is private and rated by the community
              </Text>
            </View>
          </GlassCard>
        )}
      </ScrollView>
      <View style={styles.footer}>
        <Button label="Finish Setup" onPress={finish} disabled={selected === null} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, paddingBottom: 24 },
  options: { paddingHorizontal: 24, marginTop: 24, gap: 12 },
  perkRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  perkText: { flex: 1 },
  footer: { paddingHorizontal: 24, paddingBottom: 28, gap: 12 },
});
