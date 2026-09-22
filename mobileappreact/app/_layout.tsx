import React, { useEffect, useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { QueryClient, QueryClientProvider, FocusManager } from '@tanstack/react-query';
import { useFonts } from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
// Per-weight subpaths, not the package root: the root index eagerly requires
// all 18 faces of a family, which bundles ~1.6MB of unused .ttf per family.
import { Fraunces_400Regular } from '@expo-google-fonts/fraunces/400Regular';
import { Fraunces_400Regular_Italic } from '@expo-google-fonts/fraunces/400Regular_Italic';
import { Fraunces_500Medium } from '@expo-google-fonts/fraunces/500Medium';
import { Fraunces_600SemiBold } from '@expo-google-fonts/fraunces/600SemiBold';
import { Fraunces_700Bold } from '@expo-google-fonts/fraunces/700Bold';
import { Geist_400Regular } from '@expo-google-fonts/geist/400Regular';
import { Geist_500Medium } from '@expo-google-fonts/geist/500Medium';
import { Geist_600SemiBold } from '@expo-google-fonts/geist/600SemiBold';
import { Geist_700Bold } from '@expo-google-fonts/geist/700Bold';
import { Amiri_400Regular } from '@expo-google-fonts/amiri/400Regular';
import { Amiri_700Bold } from '@expo-google-fonts/amiri/700Bold';
import { ThemeProvider, useTheme } from '../src/theme';
import { Spinner } from '../src/components/ui/Button';
import { ThemeMode } from '../src/theme';
import { useAuthStore } from '../src/lib/auth-store';
import { useUiStore } from '../src/lib/ui-store';
import { useNotificationRouting } from '../src/lib/notifications';

SplashScreen.preventAutoHideAsync().catch(() => {});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, refetchOnWindowFocus: false },
  },
});

function Gate({ children }: { children: React.ReactNode }) {
  const { palette, isDark } = useTheme();
  // Fraunces carries the voice, Geist the interface, Amiri the Arabic.
  const [fontsLoaded] = useFonts({
    Fraunces_400Regular,
    Fraunces_400Regular_Italic,
    Fraunces_500Medium,
    Fraunces_600SemiBold,
    Fraunces_700Bold,
    Geist_400Regular,
    Geist_500Medium,
    Geist_600SemiBold,
    Geist_700Bold,
    Amiri_400Regular,
    Amiri_700Bold,
  });

  const status = useAuthStore((s) => s.status);
  const init = useAuthStore((s) => s.init);
  const hydrate = useUiStore((s) => s.hydrate);
  useNotificationRouting();

  useEffect(() => {
    init();
    hydrate();
  }, [init, hydrate]);

  useEffect(() => {
    if (fontsLoaded && status !== 'loading') {
      SplashScreen.hideAsync().catch(() => {});
    }
  }, [fontsLoaded, status]);

  if (!fontsLoaded || status === 'loading') {
    return (
      <View style={[styles.boot, { backgroundColor: palette.isDark ? '#0A0C1A' : '#F3F2F9' }]}>
        <Spinner color={palette.teal} size={26} />
      </View>
    );
  }
  return <>{children}</>;
}

export default function RootLayout() {
  const preference = useUiStore((s) => (s.hydrated ? s.themePreference : 'system')) as ThemeMode;

  return (
    <GestureHandlerRootView style={styles.fill}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider preference={preference}>
            <Gate>
              <StatusBar style="auto" />
              <Stack
                screenOptions={{
                  headerShown: false,
                  contentStyle: { backgroundColor: 'transparent' },
                  animation: 'fade_from_bottom',
                  animationDuration: 320,
                }}
              >
                <Stack.Screen name="index" />
                <Stack.Screen name="(auth)" />
                <Stack.Screen name="onboarding" />
                <Stack.Screen name="(tabs)" />
                <Stack.Screen name="intervention" options={{ animation: 'fade' }} />
                <Stack.Screen name="call/[sessionId]" options={{ animation: 'fade' }} />
                <Stack.Screen name="incoming-call" options={{ animation: 'fade', gestureEnabled: false }} />
                <Stack.Screen name="call-rating" options={{ animation: 'fade' }} />
                <Stack.Screen name="milestone/[days]" options={{ animation: 'fade' }} />
              </Stack>
            </Gate>
          </ThemeProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  boot: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
