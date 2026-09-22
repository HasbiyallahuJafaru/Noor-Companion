import { Redirect } from 'expo-router';
import { useAuthStore } from '../src/lib/auth-store';
import { AuroraBackground } from '../src/components/core/AuroraBackground';
import { Text, StyleSheet, View } from 'react-native';

/**
 * Entry gate. Mirrors the Flutter router redirects:
 * unauthenticated → /login, authenticated + !onboarded → onboarding,
 * otherwise the tab shell.
 */
export default function Index() {
  const { status, user, onboarded } = useAuthStore();

  if (status === 'loading') {
    return (
      <View style={[styles.fill, { backgroundColor: '#10122A' }]}>
        <AuroraBackground />
        <View style={styles.brand}>
          <Text style={styles.arabic}>نور</Text>
        </View>
      </View>
    );
  }

  if (status === 'unauthenticated') return <Redirect href="/(auth)/login" />;
  if (!onboarded && user?.role === 'user') return <Redirect href="/onboarding/addiction" />;
  return <Redirect href="/(tabs)" />;
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  brand: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  arabic: { fontSize: 72, color: '#FFFFFF', fontWeight: '700' },
});
