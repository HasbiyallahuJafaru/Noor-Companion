import React, { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withSequence,
  withTiming,
  withDelay,
  cancelAnimation,
  Easing,
} from 'react-native-reanimated';
import { useTheme } from '../../src/theme';
import { PressableScale } from '../../src/components';
import { InterventionShell } from '../../src/components/shared/InterventionShell';

const CYCLES = 3;
const PHASE = 4; // seconds per phase: inhale / hold / exhale

/** Step 2: guided box breathing, three cycles, then auto-advance. */
export default function InterventionBreathing() {
  const { palette, type } = useTheme();
  const scale = useSharedValue(0.55);
  const [phase, setPhase] = useState('Inhale');
  const [cycle, setCycle] = useState(1);
  const done = useRef(false);

  useEffect(() => {
    const total = CYCLES * 3 * PHASE * 1000;
    scale.value = withDelay(
      400,
      withRepeat(
        withSequence(
          withTiming(1, { duration: PHASE * 1000, easing: Easing.inOut(Easing.sin) }),
          withTiming(1, { duration: PHASE * 1000, easing: Easing.inOut(Easing.quad) }),
          withTiming(0.55, { duration: PHASE * 1000, easing: Easing.inOut(Easing.sin) }),
        ),
        CYCLES,
      ),
    );
    // Phase label ticker: inhale → hold → exhale per cycle
    let elapsed = 0;
    const id = setInterval(() => {
      elapsed += 500;
      const inCycle = elapsed % (PHASE * 3 * 1000);
      const nextPhase = inCycle < PHASE * 1000 ? 'Inhale' : inCycle < PHASE * 2 * 1000 ? 'Hold' : 'Exhale';
      setPhase(nextPhase);
      const nextCycle = Math.min(Math.floor(elapsed / (PHASE * 3 * 1000)) + 1, CYCLES);
      setCycle(nextCycle);
      if (elapsed >= total && !done.current) {
        done.current = true;
        router.push('/intervention/task');
      }
    }, 500);
    const timeout = setTimeout(() => {
      if (!done.current) {
        done.current = true;
        router.push('/intervention/task');
      }
    }, total + 2000);
    return () => {
      clearInterval(id);
      clearTimeout(timeout);
      cancelAnimation(scale);
    };
  }, [scale]);

  const circle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  return (
    <InterventionShell step={2}>
      <View style={[styles.fill, styles.center]}>
        <Text style={type.heading(palette.text)}>Breathe with the circle</Text>
        <View style={styles.orbHost}>
          <View style={[styles.orbHalo, { backgroundColor: `${palette.teal}22` }]} />
          <Animated.View style={[styles.orb, { backgroundColor: palette.tealSoft }, circle]}>
            <View style={[styles.orbCore, { backgroundColor: palette.teal }]} />
          </Animated.View>
        </View>
        <Text style={[type.headingMedium(palette.text), { marginTop: 28 }]}>{phase}</Text>
        <Text style={[type.caption(palette.textMuted), { marginTop: 6 }]}>
          Cycle {cycle} of {CYCLES}
        </Text>
        <PressableScale haptic="light" onPress={() => router.push('/intervention/task')} style={styles.skip}>
          <Text style={[type.bodySmall(palette.textSecondary), { textDecorationLine: 'underline' }]}>
            Skip breathing
          </Text>
        </PressableScale>
      </View>
    </InterventionShell>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  center: { alignItems: 'center', justifyContent: 'center', padding: 24 },
  orbHost: { width: 260, height: 260, alignItems: 'center', justifyContent: 'center', marginTop: 40 },
  orbHalo: {
    position: 'absolute',
    width: 250,
    height: 250,
    borderRadius: 125,
  },
  orb: {
    width: 230,
    height: 230,
    borderRadius: 115,
    alignItems: 'center',
    justifyContent: 'center',
  },
  orbCore: {
    width: 12,
    height: 12,
    borderRadius: 6,
    opacity: 0.9,
  },
  skip: { marginTop: 44, padding: 10 },
});
