/**
 * Backdrop registry: which photograph sits behind a screen, how far it is
 * pushed back, and the scrim that guarantees text stays readable on top of it.
 *
 * Two shapes of recipe live here. The everyday canvas is a *material*: a
 * blurred stone texture, full-bleed and near-even, tinted back to brand. The
 * entry and celebration backdrops are *scenes*: the photograph is atmosphere in
 * the top third and has fully resolved into flat canvas colour by the time
 * content starts. Either way nothing is asked to be legible over raw imagery.
 *
 * Imagery: Unsplash and Pexels, both free for commercial use.
 * See assets/bg/CREDITS.md for per-image provenance.
 */

export type BackdropVariant = 'canvas' | 'texture' | 'sanctuary' | 'medallion';

export const backdropSources = {
  texture: require('../../assets/bg/canvas-texture.jpg'),
  night: require('../../assets/bg/canvas-night.jpg'),
  dawn: require('../../assets/bg/canvas-dawn.jpg'),
  arch: require('../../assets/bg/arch-sanctuary.jpg'),
  medallion: require('../../assets/bg/medallion-gold.jpg'),
  grain: require('../../assets/bg/grain.png'),
};

export type BackdropRecipe = {
  source: number;
  /** How present the photograph is before the scrim lands on it. */
  imageOpacity: number;
  /** Softening so the photo never competes with type for attention. */
  blurRadius: number;
  /** Vertical scrim, top → bottom. Last stop is always the flat canvas. */
  scrim: readonly [string, string, ...string[]];
  scrimLocations: readonly [number, number, ...number[]];
  /** Aurora orbs are dialled back when a photograph already carries texture. */
  orbOpacity: number;
  grainOpacity: number;
  /** Medallion forces light-on-dark regardless of the user's theme. */
  forcesDark: boolean;
};

/**
 * The everyday app canvas — a photograph that stays visible the whole way down.
 *
 * Dark mode is a lamplit mosque interior, light mode a pale dawn sky. The scrim
 * has four stops rather than three because the interesting part of each photo
 * is at the top, which is also where the greeting sits: it darkens hard behind
 * the header, opens up through the middle so the image actually reads, then
 * closes again at the bottom so the tab bar has something solid to sit on.
 */
const canvas = (isDark: boolean): BackdropRecipe =>
  isDark
    ? {
        source: backdropSources.night,
        imageOpacity: 0.9,
        blurRadius: 3,
        scrim: [
          'rgba(10,12,26,0.74)',
          'rgba(10,12,26,0.46)',
          'rgba(10,12,26,0.40)',
          'rgba(10,12,26,0.66)',
        ],
        scrimLocations: [0, 0.22, 0.6, 1],
        orbOpacity: 0.3,
        grainOpacity: 0.35,
        forcesDark: false,
      }
    : {
        source: backdropSources.dawn,
        imageOpacity: 0.88,
        blurRadius: 3,
        scrim: [
          'rgba(243,242,249,0.66)',
          'rgba(243,242,249,0.40)',
          'rgba(243,242,249,0.42)',
          'rgba(243,242,249,0.66)',
        ],
        scrimLocations: [0, 0.22, 0.6, 1],
        orbOpacity: 0.35,
        grainOpacity: 0.25,
        forcesDark: false,
      };

/**
 * The stone-texture canvas, kept selectable.
 *
 * This is a flat, subjectless material, so it can only ever be a surface — at
 * any setting where it is visible at all it reads as grey concrete rather than
 * as imagery, and it pulls the whole app off the lavender/ink palette. These
 * numbers are the most visible it gets while staying usable; switch the default
 * in `backdrop()` below to use it everywhere.
 */
const texture = (isDark: boolean): BackdropRecipe =>
  isDark
    ? {
        source: backdropSources.texture,
        imageOpacity: 0.55,
        blurRadius: 4,
        scrim: ['rgba(10,12,26,0.42)', 'rgba(10,12,26,0.52)', 'rgba(10,12,26,0.64)'],
        scrimLocations: [0, 0.55, 1],
        orbOpacity: 0.5,
        grainOpacity: 0.2,
        forcesDark: false,
      }
    : {
        source: backdropSources.texture,
        imageOpacity: 1,
        blurRadius: 4,
        scrim: ['rgba(243,242,249,0.20)', 'rgba(240,239,248,0.30)', 'rgba(243,242,249,0.42)'],
        scrimLocations: [0, 0.55, 1],
        orbOpacity: 0.55,
        grainOpacity: 0.15,
        forcesDark: false,
      };

/**
 * Entry moments — welcome, auth, onboarding. The photograph is allowed to
 * stay present much further down the screen because there is less content.
 */
const sanctuary = (isDark: boolean): BackdropRecipe =>
  isDark
    ? {
        source: backdropSources.arch,
        imageOpacity: 0.72,
        blurRadius: 1,
        scrim: ['rgba(10,12,26,0.2)', 'rgba(10,12,26,0.62)', 'rgba(10,12,26,0.95)'],
        scrimLocations: [0, 0.5, 0.92],
        orbOpacity: 0.35,
        grainOpacity: 0.55,
        forcesDark: false,
      }
    : {
        source: backdropSources.dawn,
        imageOpacity: 0.62,
        blurRadius: 0,
        scrim: ['rgba(243,242,249,0.12)', 'rgba(243,242,249,0.7)', 'rgba(243,242,249,0.97)'],
        scrimLocations: [0, 0.48, 0.9],
        orbOpacity: 0.5,
        grainOpacity: 0.3,
        forcesDark: false,
      };

/**
 * Celebration moments — upgrade, milestone. Gold calligraphy on ink, dark in
 * both themes: these screens are meant to feel like a different, richer room.
 */
const medallion = (): BackdropRecipe => ({
  source: backdropSources.medallion,
  imageOpacity: 0.55,
  blurRadius: 2,
  scrim: ['rgba(8,10,24,0.35)', 'rgba(8,10,24,0.82)', '#070917'],
  scrimLocations: [0, 0.45, 0.88],
  orbOpacity: 0.4,
  grainOpacity: 0.6,
  forcesDark: true,
});

export const backdrop = (variant: BackdropVariant, isDark: boolean): BackdropRecipe => {
  switch (variant) {
    case 'texture': return texture(isDark);
    case 'sanctuary': return sanctuary(isDark);
    case 'medallion': return medallion();
    default: return canvas(isDark);
  }
};

/** Foreground colours for the always-dark medallion backdrop. */
export const medallionForeground = {
  text: '#F6F3EC',
  textBody: '#D5CFC2',
  textMuted: '#9C968A',
  gold: '#F0B355',
  border: 'rgba(240,179,85,0.22)',
  glass: 'rgba(14,17,38,0.58)',
} as const;
