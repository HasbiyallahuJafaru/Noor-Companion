import { Platform } from 'react-native';
import type { TextStyle } from 'react-native';

export const FONT_SANS = 'PlusJakartaSans_400Regular';
export const FONT_SANS_MEDIUM = 'PlusJakartaSans_500Medium';
export const FONT_SANS_SEMI = 'PlusJakartaSans_600SemiBold';
export const FONT_SANS_BOLD = 'PlusJakartaSans_700Bold';
export const FONT_SANS_EXTRA = 'PlusJakartaSans_800ExtraBold';
export const FONT_ARABIC = 'Amiri_400Regular';
export const FONT_ARABIC_BOLD = 'Amiri_700Bold';

const sans = (weight: TextStyle['fontWeight']) => {
  switch (weight) {
    case '400': return FONT_SANS;
    case '500': return FONT_SANS_MEDIUM;
    case '600': return FONT_SANS_SEMI;
    case '700': return FONT_SANS_BOLD;
    case '800': return FONT_SANS_EXTRA;
    default: return FONT_SANS_MEDIUM;
  }
};

/** Web fallbacks keep Metro happy if native fonts are unavailable. */
export const typography = {
  display: (color: string): TextStyle => ({
    fontFamily: sans('800'),
    fontSize: 36,
    lineHeight: 40,
    letterSpacing: -1.2,
    color,
  }),
  heading: (color: string): TextStyle => ({
    fontFamily: sans('800'),
    fontSize: 24,
    lineHeight: 30,
    letterSpacing: -0.6,
    color,
  }),
  headingMedium: (color: string): TextStyle => ({
    fontFamily: sans('700'),
    fontSize: 18,
    lineHeight: 24,
    letterSpacing: -0.3,
    color,
  }),
  headingSmall: (color: string): TextStyle => ({
    fontFamily: sans('700'),
    fontSize: 15,
    lineHeight: 21,
    color,
  }),
  title: (color: string): TextStyle => ({
    fontFamily: sans('700'),
    fontSize: 16,
    lineHeight: 22,
    color,
  }),
  body: (color: string): TextStyle => ({
    fontFamily: sans('500'),
    fontSize: 15,
    lineHeight: 24,
    color,
  }),
  bodySmall: (color: string): TextStyle => ({
    fontFamily: sans('500'),
    fontSize: 13,
    lineHeight: 19,
    color,
  }),
  caption: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 12,
    lineHeight: 16,
    letterSpacing: 0.2,
    color,
  }),
  micro: (color: string): TextStyle => ({
    fontFamily: sans('600'),
    fontSize: 10,
    lineHeight: 14,
    letterSpacing: 0.3,
    color,
  }),
  button: (color: string): TextStyle => ({
    fontFamily: sans('700'),
    fontSize: 15,
    lineHeight: 20,
    letterSpacing: 0.1,
    color,
  }),
  numeral: (size: number, color: string): TextStyle => ({
    fontFamily: sans('800'),
    fontSize: size,
    lineHeight: Math.round(size * 1.05),
    letterSpacing: Platform.select({ ios: -1.2, android: -0.6, default: -1 })!,
    fontVariant: ['tabular-nums'],
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
