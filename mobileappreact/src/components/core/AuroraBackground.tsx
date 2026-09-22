import React, { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withSequence,
  withTiming,
  Easing,
  withDelay,
  interpolate,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../theme';
import { duration } from '../../theme/motion';

function Orb({
  size,
  color,
  from,
  to,
  period,
  delay = 0,
}: {
  size: number;
  color: string;
  from: { x: number; y: number };
  to: { x: number; y: number };
  period: number;
  delay?: number;
}) {
  const t = useSharedValue(0);
  useEffect(() => {
    t.value = withDelay(
      delay,
      withRepeat(
        withSequence(
          withTiming(1, { duration: period / 2, easing: Easing.inOut(Easing.sin) }),
          withTiming(0, { duration: period / 2, easing: Easing.inOut(Easing.sin) }),
        ),
        -1,
      ),
    );
  }, [t, period, delay]);
  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: interpolate(t.value, [0, 1], [from.x, to.x]) },
      { translateY: interpolate(t.value, [0, 1], [from.y, to.y]) },
      { scale: interpolate(t.value, [0, 1], [1, 1.18]) },
    ],
    opacity: interpolate(t.value, [0, 1], [0.75, 1]),
  }));
  return (
    <Animated.View
      pointerEvents="none"
      style={[styles.orb, { width: size, height: size, borderRadius: size / 2 }, style]}
    >
      <View style={[StyleSheet.absoluteFill, { backgroundColor: color, borderRadius: size / 2, opacity: 1 }]} />
      <BlurView intensity={60} tint="prominent" style={[StyleSheet.absoluteFill, { borderRadius: size / 2, overflow: 'hidden' }]} />
    </Animated.View>
  );
}

/**
 * The signature canvas: slow drifting glow orbs over a linear wash.
 * Ported + expanded from the Flutter PremiumBackground; every orb is a
 * blurred color field that breathes on its own long loop.
 */
export function AuroraBackground() {
  const { palette, gradients } = useTheme();
  const a = gradients.aurora;

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      <LinearGradient
        colors={palette.isDark ? ['#0A0C1A', '#0E1126'] : ['#F3F2F9', '#EDECF6']}
        style={StyleSheet.absoluteFill}
      />
      <Orb size={240} color={a.teal} from={{ x: -70, y: -40 }} to={{ x: 40, y: 30 }} period={duration.ambient} />
      <Orb size={210} color={a.gold} from={{ x: -90, y: -60 }} to={{ x: 30, y: -80 }} period={duration.ambient * 1.25} delay={2200} />
      <Orb size={270} color={a.ink} from={{ x: 80, y: 70 }} to={{ x: -60, y: -40 }} period={duration.ambient * 1.5} delay={1200} />
      <Orb size={190} color={a.violet} from={{ x: -60, y: -90 }} to={{ x: 60, y: 40 }} period={duration.ambient * 1.75} delay={3600} />
    </View>
  );
}

const styles = StyleSheet.create({
  orb: {
    position: 'absolute',
    opacity: 1,
  },
});
