import React, { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
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
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../theme';
import { duration } from '../../theme/motion';
import { backdrop, type BackdropVariant } from '../../theme/backdrops';
import { Grain } from './Grain';

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
      <View style={[StyleSheet.absoluteFill, { backgroundColor: color, borderRadius: size / 2 }]} />
      <BlurView
        intensity={60}
        tint="prominent"
        style={[StyleSheet.absoluteFill, { borderRadius: size / 2, overflow: 'hidden' }]}
      />
    </Animated.View>
  );
}

/** Slow drifting brand-colour glow, so a still photograph never feels static. */
function Orbs({ opacity }: { opacity: number }) {
  const { gradients } = useTheme();
  const a = gradients.aurora;
  if (opacity <= 0) return null;
  return (
    <View pointerEvents="none" style={[StyleSheet.absoluteFill, { opacity }]}>
      <Orb size={240} color={a.teal} from={{ x: -70, y: -40 }} to={{ x: 40, y: 30 }} period={duration.ambient} />
      <Orb size={210} color={a.gold} from={{ x: -90, y: -60 }} to={{ x: 30, y: -80 }} period={duration.ambient * 1.25} delay={2200} />
      <Orb size={270} color={a.ink} from={{ x: 80, y: 70 }} to={{ x: -60, y: -40 }} period={duration.ambient * 1.5} delay={1200} />
      <Orb size={190} color={a.violet} from={{ x: -60, y: -90 }} to={{ x: 60, y: 40 }} period={duration.ambient * 1.75} delay={3600} />
    </View>
  );
}

/**
 * The app canvas, in five layers: a flat base colour so nothing ever flashes,
 * the backdrop image behind a soft blur, a scrim that tints it back to brand
 * and guarantees contrast for whatever sits on top, the drifting orbs, and a
 * grain pass over the whole thing.
 *
 * `variant` selects the image and its whole treatment — see theme/backdrops.
 * Default 'canvas' is the everyday background used by nearly every screen.
 */
export function AppBackground({ variant = 'canvas' }: { variant?: BackdropVariant }) {
  const { palette } = useTheme();
  const recipe = backdrop(variant, palette.isDark);
  const base = recipe.forcesDark ? '#070917' : palette.background;

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      <View style={[StyleSheet.absoluteFill, { backgroundColor: base }]} />
      <Image
        source={recipe.source}
        style={[StyleSheet.absoluteFill, { opacity: recipe.imageOpacity }]}
        contentFit="cover"
        blurRadius={recipe.blurRadius}
        cachePolicy="memory-disk"
        transition={420}
        accessible={false}
      />
      <LinearGradient
        colors={recipe.scrim}
        locations={recipe.scrimLocations}
        style={StyleSheet.absoluteFill}
      />
      <Orbs opacity={recipe.orbOpacity} />
      <Grain opacity={recipe.grainOpacity} />
    </View>
  );
}

/** Previous name for this component; kept so older call sites keep resolving. */
export const AuroraBackground = AppBackground;

const styles = StyleSheet.create({
  orb: { position: 'absolute' },
});
