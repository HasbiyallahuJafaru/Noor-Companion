/**
 * Motion language: spring physics, one out-easing family, restrained durations.
 * Every animation communicates hierarchy, feedback, or a state change.
 */
import { FadeIn, FadeInDown, FadeInUp, FadeOut, ZoomIn, withSpring, Easing } from 'react-native-reanimated';

export const spring = {
  /** Standard press + small translations. */
  gentle: { damping: 20, stiffness: 200, mass: 1 },
  /** Playful pops: active pill, counters, badges. */
  snappy: { damping: 15, stiffness: 260, mass: 0.9 },
  /** Celebrations: milestone badges, overlays. */
  bouncy: { damping: 12, stiffness: 210, mass: 1 },
} as const;

export const easing = {
  out: Easing.bezier(0.16, 1, 0.3, 1),
  inOut: Easing.bezier(0.65, 0, 0.35, 1),
  soft: Easing.bezier(0.33, 1, 0.68, 1),
} as const;

export const duration = {
  fast: 140,
  base: 240,
  slow: 380,
  ambient: 14000,
} as const;

/** Staggered list entrance: items rise + settle with a spring. */
export const enterList = (i: number, step = 55) =>
  FadeInDown.delay(Math.min(i, 12) * step)
    .springify()
    .damping(spring.gentle.damping)
    .stiffness(spring.gentle.stiffness);

export const enterScreen = () =>
  FadeInDown.duration(duration.slow).easing(easing.out);

export const enterFade = (delay = 0) =>
  FadeIn.delay(delay).duration(duration.base).easing(easing.out);

export const enterRise = (delay = 0) =>
  FadeInUp.delay(delay).springify().damping(spring.gentle.damping).stiffness(spring.gentle.stiffness);

export const enterPop = (delay = 0) =>
  ZoomIn.delay(delay).springify().damping(spring.snappy.damping).stiffness(spring.snappy.stiffness);

export const exitFade = () => FadeOut.duration(duration.fast);

export { withSpring };
