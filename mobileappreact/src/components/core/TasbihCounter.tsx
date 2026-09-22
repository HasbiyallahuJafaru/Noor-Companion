import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import Svg, { Circle, Defs, LinearGradient as SvgGradient, Stop } from 'react-native-svg';
import Animated, {
  useSharedValue,
  useAnimatedProps,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withTiming,
  useDerivedValue,
} from 'react-native-reanimated';
import { RotateCcw } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { PressableScale } from '../ui/PressableScale';
import { haptic } from '../../lib/haptics';
import { spring } from '../../theme/motion';

const SIZE = 200;
const R = 88;
const STROKE = 7;
const CIRC = 2 * Math.PI * R;
const AnimatedCircle = Animated.createAnimatedComponent(Circle);

interface TasbihCounterProps {
  target: number;
  count: number;
  onTap: () => void;
  onReset: () => void;
}

/**
 * The tasbih: a large breathing tap surface with a gradient progress arc.
 * Each tap pops the numeral with spring physics; the target completes with a
 * success haptic.
 */
export function TasbihCounter({ target, count, onTap, onReset }: TasbihCounterProps) {
  const { palette, type } = useTheme();
  const progress = Math.min(count / target, 1);
  const p = useSharedValue(0);
  const pop = useSharedValue(1);
  const complete = count >= target;
  const accent = complete ? palette.gold : palette.teal;

  useEffect(() => {
    p.value = withSpring(progress, spring.gentle);
  }, [progress, p]);

  const circleProps = useAnimatedProps(() => ({
    strokeDashoffset: CIRC * (1 - p.value),
  }));

  const handleTap = () => {
    if (complete) return;
    pop.value = withSequence(
      withSpring(0.955, { damping: 12, stiffness: 400 }),
      withSpring(1, spring.snappy),
    );
    onTap();
  };

  const pressStyle = useAnimatedStyle(() => ({ transform: [{ scale: pop.value }] }));

  return (
    <View style={styles.wrap}>
      <Pressable onPress={handleTap} style={styles.tapArea}>
        <Animated.View style={pressStyle}>
          <View style={[styles.circle, { borderColor: complete ? palette.goldSoft : palette.tealSoft }]}>
            <Svg width={SIZE} height={SIZE} style={StyleSheet.absoluteFill}>
              <Defs>
                <SvgGradient id="tasbihGrad" x1="0" y1="0" x2="1" y2="1">
                  <Stop offset="0" stopColor={accent} />
                  <Stop offset="1" stopColor={complete ? palette.goldDeep : palette.tealDeep} />
                </SvgGradient>
              </Defs>
              <Circle
                cx={SIZE / 2}
                cy={SIZE / 2}
                r={R}
                stroke={palette.isDark ? 'rgba(255,255,255,0.07)' : 'rgba(23,25,48,0.06)'}
                strokeWidth={STROKE}
                fill="none"
              />
              <AnimatedCircle
                cx={SIZE / 2}
                cy={SIZE / 2}
                r={R}
                stroke="url(#tasbihGrad)"
                strokeWidth={STROKE}
                fill="none"
                strokeLinecap="round"
                strokeDasharray={CIRC}
                animatedProps={circleProps}
                transform={`rotate(-90 ${SIZE / 2} ${SIZE / 2})`}
              />
            </Svg>
            <View style={styles.center}>
              <Text style={type.numeral(52, accent)}>{count}</Text>
              <Text style={type.caption(palette.textMuted)}>of {target}</Text>
            </View>
          </View>
        </Animated.View>
      </Pressable>
      <PressableScale haptic="light" onPress={onReset} style={styles.resetRow}>
        <RotateCcw size={14} color={palette.textMuted} strokeWidth={2} />
        <Text style={type.caption(palette.textMuted)}> Reset</Text>
      </PressableScale>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center' },
  tapArea: { alignItems: 'center' },
  circle: {
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  center: { position: 'absolute', alignItems: 'center' },
  resetRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 14,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
  },
});
