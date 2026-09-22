import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Circle, Defs, LinearGradient as SvgGradient, Stop } from 'react-native-svg';
import Animated, {
  useSharedValue,
  useAnimatedProps,
  withTiming,
  withSpring,
  useAnimatedReaction,
  runOnJS,
} from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { spring } from '../../theme/motion';
import { ARC_MILESTONES } from '../../lib/types';

const R = 56;
const STROKE = 8;
const C = 2 * Math.PI * R;
const AnimatedCircle = Animated.createAnimatedComponent(Circle);

/**
 * The streak ring: a gradient progress arc toward the next milestone with a
 * count-up numeral landing in the middle. Milestone state swaps teal for gold.
 */
export function StreakRing({
  days,
  size = 128,
  milestone = false,
}: {
  days: number;
  size?: number;
  milestone?: boolean;
}) {
  const { palette } = useTheme();
  const next = ARC_MILESTONES.find((m) => m > days) ?? ARC_MILESTONES[ARC_MILESTONES.length - 1];
  const progress = Math.min(days / next, 1);
  const p = useSharedValue(0);

  useEffect(() => {
    p.value = 0;
    p.value = withTiming(progress, { duration: 1100 });
  }, [days, progress, p]);

  const circleProps = useAnimatedProps(() => ({
    strokeDashoffset: C * (1 - p.value),
  }));

  const accent = milestone ? palette.gold : palette.teal;

  return (
    <View style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}>
      <Svg width={size} height={size} style={StyleSheet.absoluteFill}>
        <Defs>
          <SvgGradient id="streakGrad" x1="0" y1="0" x2="1" y2="1">
            <Stop offset="0" stopColor={accent} />
            <Stop offset="1" stopColor={milestone ? palette.goldDeep : palette.tealDeep} />
          </SvgGradient>
        </Defs>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={R}
          stroke={palette.isDark ? 'rgba(255,255,255,0.08)' : 'rgba(23,25,48,0.07)'}
          strokeWidth={STROKE}
          fill="none"
        />
        <AnimatedCircle
          cx={size / 2}
          cy={size / 2}
          r={R}
          stroke="url(#streakGrad)"
          strokeWidth={STROKE}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={C}
          animatedProps={circleProps}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
      <View style={styles.center}>
        <CountUpNumber value={days} size={40} color={accent} />
        <Text style={useTheme().type.caption(palette.textMuted)}>days</Text>
      </View>
    </View>
  );
}

/** Animated integer that eases up to value with a spring. */
export function CountUpNumber({
  value,
  size,
  color,
  suffix,
}: {
  value: number;
  size: number;
  color: string;
  suffix?: string;
}) {
  const { type } = useTheme();
  const v = useSharedValue(0);
  const [text, setText] = React.useState(`${value}`);

  useEffect(() => {
    v.value = 0;
    v.value = withSpring(value, { damping: 26, stiffness: 80 });
  }, [value, v]);

  useAnimatedReaction(
    () => Math.round(v.value),
    (current, previous) => {
      if (current !== previous) {
        runOnJS(setText)(`${current}${suffix ?? ''}`);
      }
    },
    [suffix],
  );

  return <Text style={type.numeral(size, color)}>{text}</Text>;
}

const styles = StyleSheet.create({
  center: { position: 'absolute', alignItems: 'center' },
});
