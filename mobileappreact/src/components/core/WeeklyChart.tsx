import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useTheme } from '../../theme';

const DAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/**
 * Weekly engagement bars. Today is solid teal and pops on mount; past days
 * are dimmed teal; empty days stay as hairline stubs.
 */
export function WeeklyChart({ values, avgPercent }: { values: number[]; avgPercent: number }) {
  const { palette, type, radius } = useTheme();
  const ready = useSharedValue(0);

  useEffect(() => {
    ready.value = withTiming(1, { duration: 700, easing: Easing.out(Easing.cubic) });
  }, [ready, values]);

  const max = Math.max(...values, 1);
  const todayIndex = (new Date().getDay() + 6) % 7;

  return (
    <View>
      <View style={styles.headerRow}>
        <Text style={type.caption(palette.textSecondary)}>THIS WEEK</Text>
        <Text style={type.caption(palette.teal)}>{avgPercent}% avg</Text>
      </View>
      <View style={styles.bars}>
        {values.slice(0, 7).map((v, i) => (
          <Bar
            key={i}
            value={v}
            max={max}
            color={i === todayIndex ? palette.teal : `${palette.teal}66`}
            label={DAYS[i] ?? ''}
            labelColor={i === todayIndex ? palette.teal : palette.textMuted}
            radius={radius.sm}
            isToday={i === todayIndex}
            ready={ready}
          />
        ))}
      </View>
    </View>
  );
}

function Bar({
  value,
  max,
  color,
  label,
  labelColor,
  radius,
  isToday,
  ready,
}: {
  value: number;
  max: number;
  color: string;
  label: string;
  labelColor: string;
  radius: number;
  isToday: boolean;
  ready: { value: number };
}) {
  const { type } = useTheme();
  const target = Math.max((value / max) * 88, 6);
  const style = useAnimatedStyle(() => ({
    height: Math.max(ready.value * target, 6),
  }));
  return (
    <View style={styles.barCol}>
      <View style={styles.barTrack}>
        <Animated.View
          style={[styles.bar, style, { backgroundColor: color, borderRadius: radius, opacity: isToday ? 1 : 0.55 }]}
        />
      </View>
      <Text style={[type.micro(labelColor), styles.day]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 14 },
  bars: { flexDirection: 'row', gap: 10 },
  barCol: { flex: 1, alignItems: 'center' },
  barTrack: { height: 88, justifyContent: 'flex-end', width: '100%' },
  bar: { width: '100%', minHeight: 6 },
  day: { marginTop: 8 },
});
