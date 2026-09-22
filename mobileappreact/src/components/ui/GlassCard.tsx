import React from 'react';
import { View, StyleSheet, StyleProp, ViewStyle, ViewProps } from 'react-native';
import { BlurView } from 'expo-blur';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
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
  /** Explicit glass fill — for backdrops that ignore the user's theme. */
  surface?: string;
  /** Explicit edge colour to pair with `surface`. */
  border?: string;
  /** Photograph behind the card content, in place of the glass fill. */
  image?: number;
  /** How present the photograph is under its scrim. */
  imageOpacity?: number;
  /**
   * Where the card's own content sits, so the scrim can be weighted away from
   * it: 'bottom' (the default) darkens the lower half, 'full' darkens evenly.
   */
  imageAnchor?: 'bottom' | 'full';
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
  surface,
  border,
  image,
  imageOpacity = 0.85,
  imageAnchor = 'bottom',
  ...rest
}: GlassCardProps) {
  const { palette, shadows, radius: r } = useTheme();
  const rValue = radiusOverride ?? r.lg;

  // An image card carries its own scrim instead of the glass fill — the two
  // stacked would mute the photograph into a flat wash.
  const imageScrim: readonly [string, string, ...string[]] =
    imageAnchor === 'bottom'
      ? ['rgba(8,10,22,0.18)', 'rgba(8,10,22,0.52)', 'rgba(8,10,22,0.88)']
      : ['rgba(8,10,22,0.62)', 'rgba(8,10,22,0.66)', 'rgba(8,10,22,0.74)'];

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
      {image ? (
        <>
          <Image
            source={image}
            style={[StyleSheet.absoluteFill, { opacity: imageOpacity }]}
            contentFit="cover"
            cachePolicy="memory-disk"
            transition={300}
            accessible={false}
          />
          <LinearGradient colors={imageScrim} style={StyleSheet.absoluteFill} />
        </>
      ) : (
        <>
          <BlurView
            intensity={intensity ?? (palette.isDark ? 28 : 44)}
            tint={tint ?? (palette.isDark ? 'dark' : 'light')}
            style={StyleSheet.absoluteFill}
          />
          <View
            style={[
              StyleSheet.absoluteFill,
              { backgroundColor: surface ?? (tint ? 'transparent' : palette.surfaceGlass) },
            ]}
          />
        </>
      )}
      {/* 1px light-fall border for glass edge refraction */}
      <View
        pointerEvents="none"
        style={[
          StyleSheet.absoluteFill,
          {
            borderRadius: rValue,
            borderWidth: StyleSheet.hairlineWidth + 0.5,
            borderColor:
              border ?? (image ? 'rgba(255,255,255,0.14)' : gradientBorder ? palette.teal : palette.glassBorder),
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
