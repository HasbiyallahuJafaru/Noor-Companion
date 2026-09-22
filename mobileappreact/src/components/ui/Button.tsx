import React, { useEffect, useRef } from 'react';
import { StyleSheet, View, StyleProp, ViewStyle } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  withDelay,
  withRepeat,
  withSequence,
  Easing,
  interpolate,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../theme';
import { PressableScale } from './PressableScale';
import { easing, duration } from '../../theme/motion';

export type ButtonVariant = 'primary' | 'ink' | 'gold' | 'outline' | 'ghost' | 'danger';

interface ButtonProps {
  label: string;
  onPress?: () => void;
  variant?: ButtonVariant;
  loading?: boolean;
  disabled?: boolean;
  icon?: React.ReactNode;
  fullWidth?: boolean;
  size?: 'md' | 'lg';
  style?: StyleProp<ViewStyle>;
}

/**
 * Primary buttons carry a slow shimmer sweep (ported from the Flutter
 * ShimmerButton); every press squeezes with spring physics.
 */
export function Button({
  label,
  onPress,
  variant = 'primary',
  loading = false,
  disabled = false,
  icon,
  fullWidth = true,
  size = 'lg',
  style,
}: ButtonProps) {
  const { palette, type, radius, gradients } = useTheme();
  const shimmer = useSharedValue(0);
  const mounted = useRef(false);

  useEffect(() => {
    if (variant === 'primary' && !disabled && !loading) {
      mounted.current = true;
      shimmer.value = withDelay(
        900,
        withRepeat(
          withSequence(
            withTiming(1, { duration: 1600, easing: Easing.inOut(Easing.quad) }),
            withTiming(1, { duration: 400 }),
            withTiming(0, { duration: 0 }),
          ),
          -1,
        ),
      );
      return () => {
        shimmer.value = 0;
      };
    }
  }, [variant, disabled, loading, shimmer]);

  const shimmerStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(shimmer.value, [0, 1], [-260, 260]),
      },
    ],
    opacity: interpolate(shimmer.value, [0, 1], [0, 0.28]),
  }));

  const height = size === 'lg' ? 56 : 48;

  const colors: Record<ButtonVariant, { bg: readonly string[] | string; fg: string }> = {
    primary: { bg: gradients.brand, fg: '#FFFFFF' },
    ink: { bg: gradients.ink, fg: '#FFFFFF' },
    gold: { bg: gradients.gold, fg: palette.isDark ? '#241703' : '#FFFFFF' },
    outline: { bg: 'transparent', fg: palette.teal },
    ghost: { bg: 'transparent', fg: palette.textSecondary },
    danger: { bg: [palette.danger, palette.danger], fg: '#FFFFFF' },
  };

  const c = colors[variant];
  const isGradient = Array.isArray(c.bg);

  const inner = (
    <View
      style={[
        styles.inner,
        {
          height,
          borderRadius: variant === 'outline' ? radius.md : radius.pill,
          backgroundColor: !isGradient ? (c.bg as string) : undefined,
          borderWidth: variant === 'outline' ? 1.5 : 0,
          borderColor: palette.teal,
        },
      ]}
    >
      {loading ? (
        <View style={styles.spinnerWrap}>
          <Spinner color={c.fg} />
        </View>
      ) : (
        <>
          {icon}
          <Animated.Text style={[type.button(c.fg), styles.label]}>{label}</Animated.Text>
        </>
      )}
      {isGradient && variant === 'primary' && !disabled && (
        <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, styles.shimmerMask, shimmerStyle]}>
          <LinearGradient
            colors={['transparent', 'rgba(255,255,255,0.85)', 'transparent']}
            start={{ x: 0, y: 0.5 }}
            end={{ x: 1, y: 0.5 }}
            style={StyleSheet.absoluteFill}
          />
        </Animated.View>
      )}
    </View>
  );

  return (
    <PressableScale
      onPress={onPress}
      disabled={disabled || loading}
      haptic="medium"
      style={[fullWidth && styles.full, style, disabled && styles.disabled]}
    >
      {isGradient ? (
        <LinearGradient
          colors={c.bg as readonly [string, string, ...string[]]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={{ borderRadius: variant === 'outline' ? radius.md : radius.pill }}
        >
          {inner}
        </LinearGradient>
      ) : (
        inner
      )}
    </PressableScale>
  );
}

/** Lightweight activity spinner (no dependency). */
export function Spinner({ color = '#FFFFFF', size = 22 }: { color?: string; size?: number }) {
  const { palette } = useTheme();
  const rot = useSharedValue(0);
  useEffect(() => {
    rot.value = withRepeat(
      withTiming(360, { duration: 800, easing: Easing.linear }),
      -1,
    );
  }, [rot]);
  const style = useAnimatedStyle(() => ({ transform: [{ rotate: `${rot.value}deg` }] }));
  const c = color === 'auto' ? palette.textMuted : color;
  return (
    <Animated.View
      style={[
        {
          width: size,
          height: size,
          borderRadius: size / 2,
          borderWidth: 2.5,
          borderColor: `${c}33`,
          borderTopColor: c,
        },
        style,
      ]}
    />
  );
}

const styles = StyleSheet.create({
  inner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    overflow: 'hidden',
    paddingHorizontal: 24,
  },
  full: { alignSelf: 'stretch' },
  label: { textAlign: 'center' },
  disabled: { opacity: 0.5 },
  shimmerMask: {},
  spinnerWrap: { height: 24, justifyContent: 'center' },
});
