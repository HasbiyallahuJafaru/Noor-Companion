import React, { createContext, useContext, useMemo } from 'react';
import { useColorScheme } from 'react-native';
import { light, dark, radius, spacing, shadows, gradients, type Palette } from './tokens';
import { typography } from './typography';

export type ThemeMode = 'system' | 'light' | 'dark';

type Theme = {
  palette: Palette;
  isDark: boolean;
  radius: typeof radius;
  spacing: typeof spacing;
  shadows: ReturnType<typeof shadows>;
  gradients: ReturnType<typeof gradients>;
  type: typeof typography;
  /** Explicit user override persisted in ui store; 'system' follows OS. */
  preference: ThemeMode;
};

const ThemeContext = createContext<Theme | null>(null);

export function ThemeProvider({
  preference = 'system',
  children,
}: {
  preference?: ThemeMode;
  children: React.ReactNode;
}) {
  const scheme = useColorScheme();
  const value = useMemo<Theme>(() => {
    const isDark = preference === 'system' ? scheme === 'dark' : preference === 'dark';
    const palette = isDark ? dark : light;
    return {
      palette,
      isDark,
      radius,
      spacing,
      shadows: shadows(palette),
      gradients: gradients(palette),
      type: typography,
      preference,
    };
  }, [preference, scheme]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): Theme {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used inside ThemeProvider');
  return ctx;
}
