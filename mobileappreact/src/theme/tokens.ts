/**
 * Luminous Ink design tokens.
 * Evolution of the Soft Luxury brand: teal/gold/ink identity, with a full
 * luminous dark mode as the hero experience. Light mode keeps the signature
 * lavender-grey canvas.
 */

export const light = {
  mode: 'light' as const,
  isDark: false,

  // Canvas
  background: '#F3F2F9',
  backgroundElevated: '#ECEBF5',
  surface: '#FFFFFF',
  surfaceGlass: 'rgba(255, 255, 255, 0.74)',
  surfaceGlassStrong: 'rgba(255, 255, 255, 0.92)',
  scrim: 'rgba(23, 25, 48, 0.45)',

  // Text
  text: '#16182F',
  textBody: '#3A3B52',
  textSecondary: '#55566E',
  textMuted: '#8B8CA3',
  textOnBrand: '#FFFFFF',

  // Lines
  border: '#E9E8F2',
  borderStrong: '#DDDCEA',
  glassBorder: 'rgba(255, 255, 255, 0.65)',
  hairline: 'rgba(23, 25, 48, 0.08)',

  // Brand
  teal: '#0D9488',
  tealDeep: '#0B7268',
  tealSoft: '#DDF5F2',
  tealTint: '#F0FAF8',
  gold: '#E8A33D',
  goldDeep: '#B97F23',
  goldSoft: '#FCF1DD',
  ink: '#171930',
  inkSoft: '#232544',

  // Status
  success: '#16A34A',
  successSoft: '#E5F6EB',
  danger: '#DC2626',
  dangerSoft: '#FDEAEA',
  orange: '#E67E22',
  purple: '#8E44AD',
  purpleSoft: '#F3EAF8',

  // Materials
  overlay: 'rgba(23, 25, 48, 0.55)',
  ripple: 'rgba(13, 148, 136, 0.12)',

  // Glow shadows
  shadowColor: '#171930',
  tealGlow: 'rgba(13, 148, 136, 0.28)',
  goldGlow: 'rgba(232, 163, 61, 0.30)',
};

export const dark = {
  mode: 'dark' as const,
  isDark: true,

  // Canvas — deep ink-navy
  background: '#0A0C1A',
  backgroundElevated: '#10122A',
  surface: '#161A36',
  surfaceGlass: 'rgba(22, 26, 54, 0.58)',
  surfaceGlassStrong: 'rgba(22, 26, 54, 0.92)',
  scrim: 'rgba(2, 3, 10, 0.6)',

  // Text
  text: '#F1F1FA',
  textBody: '#C6C7DD',
  textSecondary: '#9DA0BC',
  textMuted: '#6C6F92',
  textOnBrand: '#04211E',

  // Lines
  border: '#262A4D',
  borderStrong: '#313660',
  glassBorder: 'rgba(255, 255, 255, 0.09)',
  hairline: 'rgba(241, 241, 250, 0.08)',

  // Brand — luminous
  teal: '#2DD4BF',
  tealDeep: '#14B8A6',
  tealSoft: 'rgba(45, 212, 191, 0.16)',
  tealTint: 'rgba(45, 212, 191, 0.08)',
  gold: '#F0B355',
  goldDeep: '#DBA03F',
  goldSoft: 'rgba(240, 179, 85, 0.16)',
  ink: '#10122A',
  inkSoft: '#1B1F42',

  // Status
  success: '#4ADE80',
  successSoft: 'rgba(74, 222, 128, 0.14)',
  danger: '#F87171',
  dangerSoft: 'rgba(248, 113, 113, 0.14)',
  orange: '#FB923C',
  purple: '#C084FC',
  purpleSoft: 'rgba(192, 132, 252, 0.14)',

  // Materials
  overlay: 'rgba(2, 3, 10, 0.65)',
  ripple: 'rgba(45, 212, 191, 0.14)',

  // Glow shadows
  shadowColor: '#000000',
  tealGlow: 'rgba(45, 212, 191, 0.30)',
  goldGlow: 'rgba(240, 179, 85, 0.28)',
};

export type Palette = Omit<typeof light, 'mode' | 'isDark'> & {
  mode: 'light' | 'dark';
  isDark: boolean;
};

export const radius = {
  xs: 8,
  sm: 12,
  md: 16,
  lg: 22,
  xl: 28,
  pill: 999,
} as const;

export const spacing = (n: number) => n * 4;

/** Dark surfaces get soft elevation instead of heavy ink shadows. */
export const shadows = (p: Palette) => ({
  sm: {
    shadowColor: p.shadowColor,
    shadowOpacity: p.mode === 'dark' ? 0.5 : 0.08,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  md: {
    shadowColor: p.shadowColor,
    shadowOpacity: p.mode === 'dark' ? 0.55 : 0.1,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 6 },
    elevation: 5,
  },
  lg: {
    shadowColor: p.shadowColor,
    shadowOpacity: p.mode === 'dark' ? 0.6 : 0.13,
    shadowRadius: 40,
    shadowOffset: { width: 0, height: 12 },
    elevation: 9,
  },
  tealGlow: {
    shadowColor: p.mode === 'dark' ? '#2DD4BF' : '#0D9488',
    shadowOpacity: 0.35,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
  },
  goldGlow: {
    shadowColor: p.mode === 'dark' ? '#F0B355' : '#E8A33D',
    shadowOpacity: 0.35,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
  },
});

/** Brand gradients, palette-aware. */
export const gradients = (p: Palette) => ({
  brand: p.mode === 'dark'
    ? ['#14B8A6', '#0D9488'] as const
    : ['#0D9488', '#0B7268'] as const,
  ink: p.mode === 'dark'
    ? ['#1B1F42', '#10122A'] as const
    : ['#171930', '#232544'] as const,
  gold: ['#F0B355', '#E8A33D'] as const,
  aurora: {
    ink: p.mode === 'dark' ? 'rgba(43, 49, 106, 0.3)' : 'rgba(23, 25, 48, 0.05)',
    teal: p.mode === 'dark' ? 'rgba(20, 184, 166, 0.12)' : 'rgba(13, 148, 136, 0.08)',
    gold: p.mode === 'dark' ? 'rgba(240, 179, 85, 0.09)' : 'rgba(232, 163, 61, 0.09)',
    violet: p.mode === 'dark' ? 'rgba(124, 106, 240, 0.11)' : 'rgba(124, 106, 240, 0.06)',
  },
});
