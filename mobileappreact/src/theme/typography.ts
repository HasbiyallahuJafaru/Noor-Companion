/**
 * Type system: an editorial pairing rather than a single UI sans.
 *
 * Fraunces (soft, high-contrast serif) carries every voice moment — greetings,
 * section headings, streak numerals, pull quotes. Geist (neutral grotesque with
 * excellent small sizes and true tabular figures) carries every functional
 * moment — body copy, labels, buttons, data. Amiri stays for Arabic.
 *
 * The split is deliberate: serif = what the app says, sans = what the app does.
 */
import { Platform } from 'react-native';
import type { TextStyle } from 'react-native';

/** Display serif — headings, numerals, quotes. */
export const FONT_SERIF = 'Fraunces_400Regular';
export const FONT_SERIF_MEDIUM = 'Fraunces_500Medium';
export const FONT_SERIF_SEMI = 'Fraunces_600SemiBold';
export const FONT_SERIF_BOLD = 'Fraunces_700Bold';
export const FONT_SERIF_ITALIC = 'Fraunces_400Regular_Italic';

/** Interface sans — body, labels, buttons, data. */
export const FONT_SANS = 'Geist_400Regular';
export const FONT_SANS_MEDIUM = 'Geist_500Medium';
export const FONT_SANS_SEMI = 'Geist_600SemiBold';
export const FONT_SANS_BOLD = 'Geist_700Bold';

export const FONT_ARABIC = 'Amiri_400Regular';
export const FONT_ARABIC_BOLD = 'Amiri_700Bold';

const sans = (weight: TextStyle['fontWeight']) => {
  switch (weight) {
    case '400': return FONT_SANS;
    case '500': return FONT_SANS_MEDIUM;
    case '600': return FONT_SANS_SEMI;
    case '700': return FONT_SANS_BOLD;
    default: return FONT_SANS_MEDIUM;
  }
};

const serif = (weight: TextStyle['fontWeight']) => {
  switch (weight) {
    case '400': return FONT_SERIF;
    case '500': return FONT_SERIF_MEDIUM;
    case '600': return FONT_SERIF_SEMI;
    case '700': return FONT_SERIF_BOLD;
    default: return FONT_SERIF_SEMI;
  }
};

/**
 * Optical tracking: serifs at display sizes need negative tracking to stop
 * looking loose, small sans labels need positive tracking to stop looking tight.
 */
export const typography = {
  /** Hero moment — one per screen at most. */
  display: (color: string): TextStyle => ({
    fontFamily: serif('600'),
    fontSize: 38,
    lineHeight: 43,
    letterSpacing: -1.1,
    color,
  }),
  /** Screen title / greeting. */
  heading: (color: string): TextStyle => ({
    fontFamily: serif('600'),
    fontSize: 27,
    lineHeight: 33,
    letterSpacing: -0.7,
    color,
  }),
  /** Section heading inside a screen. */
  headingMedium: (color: string): TextStyle => ({
    fontFamily: serif('600'),
    fontSize: 19,
    lineHeight: 25,
    letterSpacing: -0.35,
    color,
  }),
  /** Small heading in chrome (nav bars, dense rows) — sans for legibility. */
  headingSmall: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 15,
    lineHeight: 21,
    letterSpacing: -0.1,
    color,
  }),
  /** List-row title. */
  title: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 16,
    lineHeight: 22,
    letterSpacing: -0.15,
    color,
  }),
  /** Serif list-row title, for content rows that should feel authored. */
  titleSerif: (color: string): TextStyle => ({
    fontFamily: serif('600'),
    fontSize: 17,
    lineHeight: 23,
    letterSpacing: -0.3,
    color,
  }),
  body: (color: string): TextStyle => ({
    fontFamily: sans('400'),
    fontSize: 15,
    lineHeight: 24,
    letterSpacing: -0.05,
    color,
  }),
  bodySmall: (color: string): TextStyle => ({
    fontFamily: sans('400'),
    fontSize: 13.5,
    lineHeight: 20,
    color,
  }),
  caption: (color: string): TextStyle => ({
    fontFamily: sans('500'),
    fontSize: 12,
    lineHeight: 16,
    letterSpacing: 0.1,
    color,
  }),
  micro: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 10,
    lineHeight: 14,
    letterSpacing: 0.3,
    color,
  }),
  /** Small tracked-out label; caller applies textTransform if it wants caps. */
  eyebrow: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 10.5,
    lineHeight: 14,
    letterSpacing: 1.3,
    color,
  }),
  button: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 15,
    lineHeight: 20,
    letterSpacing: 0,
    color,
  }),
  /** Big expressive counters — streak days, tasbih totals. */
  numeral: (size: number, color: string): TextStyle => ({
    fontFamily: serif('600'),
    fontSize: size,
    lineHeight: Math.round(size * 1.06),
    letterSpacing: Platform.select({ ios: -1.4, android: -0.8, default: -1.2 })!,
    fontVariant: ['tabular-nums'],
    color,
  }),
  /** Aligned figures for data that sits in columns — times, durations, counts. */
  figure: (size: number, color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: size,
    lineHeight: Math.round(size * 1.25),
    letterSpacing: 0,
    fontVariant: ['tabular-nums'],
    color,
  }),
  /** Reflective copy — translations, milestone lines, intervention prompts. */
  quote: (size: number, color: string): TextStyle => ({
    fontFamily: FONT_SERIF_ITALIC,
    fontSize: size,
    lineHeight: Math.round(size * 1.5),
    letterSpacing: -0.2,
    color,
  }),
  arabic: (size: number, color: string, bold = true): TextStyle => ({
    fontFamily: bold ? FONT_ARABIC_BOLD : FONT_ARABIC,
    fontSize: size,
    lineHeight: Math.round(size * 1.8),
    color,
    textAlign: 'right',
    writingDirection: 'rtl' as const,
  }),
};
