import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { useTheme } from '../../src/theme';
import { ArabicBlock, Button } from '../../src/components';
import { InterventionShell } from '../../src/components/shared/InterventionShell';

const DUA = {
  arabic: 'أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
  transliteration: "A'ūdhu billāhi minash-shayṭānir-rajīm",
  translation: 'I seek refuge in Allah from Satan, the accursed.',
};

/** Step 1: settle with a breath. A 4px progress line fills over 10 seconds. */
export default function InterventionDua() {
  const { palette, type } = useTheme();
  const t = useSharedValue(0);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    t.value = withTiming(1, { duration: 10000, easing: Easing.linear });
    const id = setTimeout(() => setReady(true), 10000);
    return () => clearTimeout(id);
  }, [t]);

  const fill = useAnimatedStyle(() => ({
    width: `${interpolate(t.value, [0, 1], [0, 100])}%`,
  }));

  return (
    <InterventionShell step={1}>
      <View style={[styles.fill, styles.center]}>
        <Text style={type.heading(palette.text)}>Take a breath.</Text>
        <Text style={[type.body(palette.textSecondary), { marginTop: 6 }]}>Allah is with you.</Text>
        <View style={styles.dua}>
          <ArabicBlock
            animate={false}
            arabic={DUA.arabic}
            transliteration={DUA.transliteration}
            translation={DUA.translation}
          />
        </View>
        <View style={[styles.progressTrack, { backgroundColor: palette.hairline }]}>
          <Animated.View style={[styles.progressFill, { backgroundColor: palette.teal }, fill]} />
        </View>
        <Text style={type.caption(palette.textMuted)}>Breathe with the line</Text>
        {ready && (
          <Animated.View entering={require('react-native-reanimated').FadeIn.duration(240)} style={styles.cta}>
            <Button label="Continue Breathing" onPress={() => router.push('/intervention/breathing')} />
          </Animated.View>
        )}
      </View>
    </InterventionShell>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  center: { alignItems: 'center', justifyContent: 'center', padding: 24 },
  dua: { width: '100%', marginTop: 36 },
  progressTrack: {
    height: 4,
    borderRadius: 2,
    overflow: 'hidden',
    width: '70%',
    marginTop: 40,
  },
  progressFill: { height: '100%', borderRadius: 2 },
  cta: { width: '100%', marginTop: 28, paddingHorizontal: 0 },
});
