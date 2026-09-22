import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { FadeInDown, withSpring, useAnimatedStyle, useSharedValue } from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

/** "N of 3" progress line shared by the onboarding steps. */
export function OnboardingProgress({ step, total = 3 }: { step: number; total?: number }) {
  const { palette, type } = useTheme();
  const insets = useSafeAreaInsets();
  const width = useSharedValue(0);
  React.useEffect(() => {
    width.value = withSpring(step / total);
  }, [step, total, width]);
  const fill = useAnimatedStyle(() => ({ flex: width.value }));

  return (
    <View style={[styles.wrap, { paddingTop: insets.top + 16 }]}>
      <Text style={type.caption(palette.textMuted)}>
        {step} of {total}
      </Text>
      <View style={[styles.track, { backgroundColor: palette.hairline }]}>
        <Animated.View style={[styles.fillBase, { backgroundColor: palette.teal }, fill]} />
      </View>
    </View>
  );
}

export function OnboardingHeading({ title, subtitle }: { title: string; subtitle?: string }) {
  const { palette, type } = useTheme();
  return (
    <Animated.View entering={FadeInDown.springify().damping(18)} style={styles.heading}>
      <Text style={type.heading(palette.text)}>{title}</Text>
      {subtitle ? <Text style={[type.body(palette.textSecondary), styles.subtitle]}>{subtitle}</Text> : null}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: { paddingHorizontal: 24 },
  track: { height: 4, borderRadius: 2, marginTop: 10, flexDirection: 'row', overflow: 'hidden' },
  fillBase: { height: '100%', borderRadius: 2 },
  heading: { paddingHorizontal: 24, marginTop: 34, gap: 8 },
  subtitle: { marginTop: 2 },
});
