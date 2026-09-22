import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { X } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { AuroraBackground } from '../core/AuroraBackground';
import { PressableScale, Button } from '..';

/**
 * Shared chrome for the 4-step crisis flow: back suppressed (PopScope
 * equivalent), X exits home, "N of 4" progress line at the top.
 */
export function InterventionShell({
  step,
  children,
}: {
  step: number;
  children: React.ReactNode;
}) {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AuroraBackground />
      <View style={styles.topRow}>
        <View style={[styles.track, { backgroundColor: palette.hairline }]}>
          {[1, 2, 3, 4].map((i) => (
            <View
              key={i}
              style={[
                styles.seg,
                i <= step && { backgroundColor: palette.teal },
                i === step && { borderRadius: 3 },
                { flex: 1 },
              ]}
            />
          ))}
        </View>
        <PressableScale
          haptic="light"
          pressScale={0.9}
          onPress={() => router.replace('/(tabs)')}
          style={[styles.close, { backgroundColor: palette.surface, borderColor: palette.border }]}
        >
          <X size={18} color={palette.text} strokeWidth={2.2} />
        </PressableScale>
      </View>
      <View style={styles.body}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    paddingHorizontal: 24,
    paddingTop: 12,
  },
  track: { flex: 1, height: 4, borderRadius: 2, flexDirection: 'row', gap: 6 },
  seg: { height: '100%', borderRadius: 2, opacity: 0.9 },
  close: {
    width: 38,
    height: 38,
    borderRadius: 19,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: { flex: 1 },
});
