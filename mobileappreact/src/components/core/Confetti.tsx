import React, { useEffect, useMemo } from 'react';
import { View, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withDelay,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useTheme } from '../../theme';

const COLORS_COUNT = 18;

/**
 * Celebration confetti burst for milestone moments. Deterministic pseudo-random
 * layout so rerenders don't jump; runs ~2.8s then fades.
 */
export function Confetti({ run = true }: { run?: boolean }) {
  const { palette } = useTheme();
  const pieces = useMemo(() => {
    const colors = [palette.teal, palette.gold, palette.purple, palette.success, palette.text];
    return Array.from({ length: COLORS_COUNT }, (_, i) => ({
      id: i,
      left: ((i * 61) % 100) + (i % 3) * 3,
      size: 6 + ((i * 7) % 3) * 3,
      color: colors[i % colors.length],
      delay: (i % 6) * 120,
      drift: ((i * 37) % 60) - 30,
      rotate: 180 + ((i * 53) % 360),
      round: i % 3 === 0,
    }));
  }, [palette]);

  if (!run) return null;

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {pieces.map((p) => (
        <Piece key={p.id} {...p} />
      ))}
    </View>
  );
}

function Piece({
  left,
  size,
  color,
  delay,
  drift,
  rotate,
  round,
}: {
  left: number;
  size: number;
  color: string;
  delay: number;
  drift: number;
  rotate: number;
  round: boolean;
}) {
  const t = useSharedValue(0);
  useEffect(() => {
    t.value = withDelay(
      delay,
      withTiming(1, { duration: 2600, easing: Easing.out(Easing.quad) }),
    );
  }, [t, delay]);

  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: t.value * drift },
      { translateY: t.value * t.value * 520 - 40 },
      { rotate: `${t.value * rotate}deg` },
    ],
    opacity: t.value < 0.85 ? 1 : (1 - t.value) * 6.6,
  }));

  return (
    <Animated.View
      style={[
        {
          position: 'absolute',
          top: -20,
          left: `${left}%`,
          width: size,
          height: round ? size : size * 2.1,
          borderRadius: round ? size / 2 : 2,
          backgroundColor: color,
        },
        style,
      ]}
    />
  );
}
