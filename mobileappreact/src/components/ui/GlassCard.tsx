import React from 'react';
import { View, StyleSheet, StyleProp, ViewStyle, ViewProps } from 'react-native';
import { BlurView } from 'expo-blur';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { enterList } from '../../theme/motion';

interface GlassCardProps extends ViewProps {
  children: React.ReactNode;
  index?: number;
  radiusOverride?: number;
  intensity?: number;
  tint?: 'light' | 'dark' | 'prominent';
  style?: StyleProp<ViewStyle>;
  padding?: number;
  animate?: boolean;
  gradientBorder?: boolean;
}

/**
 * Signature surface: frosted glass over the aurora canvas with a light-fall
 * border and a soft ink shadow. `index` staggers the entrance.
 */
export function GlassCard({
  children,
  index = 0,
  radiusOverride,
  intensity,
  tint,
  style,
  padding = 20,
  animate = true,
  gradientBorder = false,
  ...rest
}: GlassCardProps) {
  const { palette, shadows, radius: r } = useTheme();
  const rValue = radiusOverride ?? r.lg;

  return (
    <Animated.View
      entering={animate ? enterList(index) : undefined}
      style={[
        {
          borderRadius: rValue,
          overflow: 'hidden',
          ...shadows.md,
        },
        style,
      ]}
      {...rest}
    >
      <BlurView
        intensity={intensity ?? (palette.isDark ? 28 : 44)}
        tint={tint ?? (palette.isDark ? 'dark' : 'light')}
        style={StyleSheet.absoluteFill}
      />
      <View
        style={[
          StyleSheet.absoluteFill,
          { backgroundColor: tint ? 'transparent' : palette.surfaceGlass },
        ]}
      />
      {/* 1px light-fall border for glass edge refraction */}
      <View
        pointerEvents="none"
        style={[
          StyleSheet.absoluteFill,
          {
            borderRadius: rValue,
            borderWidth: StyleSheet.hairlineWidth + 0.5,
            borderColor: gradientBorder ? palette.teal : palette.glassBorder,
          },
        ]}
      />
      <View style={{ padding, borderRadius: rValue }}>{children}</View>
    </Animated.View>
  );
}

/** Solid surface card for dense lists where blur is overkill. */
export function Card({
  children,
  index,
  style,
  padding = 18,
  ...rest
}: {
  children: React.ReactNode;
  index?: number;
  style?: StyleProp<ViewStyle>;
  padding?: number;
} & ViewProps) {
  const { palette, shadows, radius: r } = useTheme();
  return (
    <Animated.View
      entering={index !== undefined ? enterList(index) : undefined}
      style={[
        {
          backgroundColor: palette.surface,
          borderRadius: r.lg,
          borderWidth: 1,
          borderColor: palette.border,
          padding,
          ...shadows.sm,
        },
        style,
      ]}
      {...rest}
    >
      {children}
    </Animated.View>
  );
}
