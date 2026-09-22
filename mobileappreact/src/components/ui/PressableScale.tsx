import React, { useCallback, useRef } from 'react';
import { Pressable, PressableProps, StyleProp, ViewStyle, StyleSheet } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  interpolate,
} from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { spring } from '../../theme/motion';

type HapticLevel = 'none' | 'light' | 'medium' | 'heavy';

interface PressableScaleProps extends Omit<PressableProps, 'children'> {
  children: React.ReactNode;
  /** Press depth: 0.9 = strong squeeze, 0.97 = subtle. */
  pressScale?: number;
  haptic?: HapticLevel;
  style?: StyleProp<ViewStyle>;
  bounceIcon?: boolean;
}

/**
 * Every tappable surface in the app. Spring press physics + an optional
 * haptic tick, so the whole UI feels physical and consistent.
 */
export function PressableScale({
  children,
  pressScale = 0.97,
  haptic = 'light',
  style,
  onPress,
  disabled,
  ...rest
}: PressableScaleProps) {
  const pressed = useSharedValue(0);

  const animated = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pressed.value, [0, 1], [1, pressScale]) }],
  }));

  const handlePress = useCallback(
    (e: Parameters<NonNullable<PressableProps['onPress']>>[0]) => {
      if (haptic !== 'none') {
        const map = {
          light: Haptics.ImpactFeedbackStyle.Light,
          medium: Haptics.ImpactFeedbackStyle.Medium,
          heavy: Haptics.ImpactFeedbackStyle.Heavy,
        } as const;
        Haptics.impactAsync(map[haptic]).catch(() => {});
      }
      onPress?.(e);
    },
    [haptic, onPress],
  );

  return (
    <Pressable
      onPress={handlePress}
      onPressIn={() => (pressed.value = withSpring(1, spring.snappy))}
      onPressOut={() => (pressed.value = withSpring(0, spring.snappy))}
      disabled={disabled}
      {...rest}
    >
      <Animated.View style={[animated, style, disabled && styles.dimmed]}>
        {children}
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  dimmed: { opacity: 0.55 },
});
