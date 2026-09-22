import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, KeyboardAvoidingView, Platform, Alert, Modal } from 'react-native';
import { router } from 'expo-router';
import { supabase } from '../../src/lib/supabase';
import { useAuthStore } from '../../src/lib/auth-store';
import { useTheme } from '../../src/theme';
import { FONT_ARABIC_BOLD } from '../../src/theme/typography';
import { AppBackground } from '../../src/components/core/AppBackground';
import { GlassCard, Input, Button, PressableScale } from '../../src/components';

import { registerPushToken } from '../../src/lib/notifications';

function LoginInner() {
  const { palette, type, radius } = useTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [resetOpen, setResetOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState('');
  const [resetSent, setResetSent] = useState(false);
  const init = useAuthStore((s) => s.init);

  const signIn = async () => {
    setError(null);
    setLoading(true);
    try {
      const { error: err } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });
      if (err) throw err;
      await init();
      registerPushToken();
      router.replace('/(tabs)');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not sign in');
    } finally {
      setLoading(false);
    }
  };

  const sendReset = async () => {
    try {
      const { error: err } = await supabase.auth.resetPasswordForEmail(resetEmail.trim());
      if (err) throw err;
      setResetSent(true);
    } catch (e) {
      Alert.alert('Reset failed', e instanceof Error ? e.message : 'Please try again.');
    }
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AppBackground variant="sanctuary" />
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.fill}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled" bounces={false}>
          <View style={styles.header}>
            <Text style={[styles.arabic, { color: palette.isDark ? palette.gold : palette.teal }]}>نور</Text>
            <Text style={type.heading(palette.text)}>Welcome back</Text>
            <Text style={type.body(palette.textSecondary)}>Light your way back.</Text>
          </View>

          <GlassCard index={1} padding={22} style={{ marginTop: 28 }}>
            <View style={{ gap: 16 }}>
              <Input
                label="Email"
                placeholder="you@example.com"
                autoCapitalize="none"
                keyboardType="email-address"
                value={email}
                onChangeText={setEmail}
              />
              <Input
                label="Password"
                placeholder="Your password"
                secure
                value={password}
                onChangeText={setPassword}
              />
              {error && (
                <PressableScale haptic="light" onPress={() => setError(null)}>
                  <View
                    style={[
                      styles.error,
                      {
                        backgroundColor: palette.dangerSoft,
                        borderRadius: radius.md,
                        borderColor: palette.danger,
                      },
                    ]}
                  >
                    <Text style={type.bodySmall(palette.danger)}>{error}</Text>
                  </View>
                </PressableScale>
              )}
              <Button label="Sign In" onPress={signIn} loading={loading} disabled={!email || !password} />
              <PressableScale haptic="light" onPress={() => setResetOpen(true)} style={{ alignSelf: 'center' }}>
                <Text style={type.bodySmall(palette.teal)}>Forgot password?</Text>
              </PressableScale>
            </View>
          </GlassCard>

          <View style={styles.footer}>
            <Text style={type.bodySmall(palette.textSecondary)}>New to Noor Companion? </Text>
            <PressableScale haptic="light" onPress={() => router.push('/(auth)/register')}>
              <Text style={[type.bodySmall(palette.teal), { fontWeight: '700' }]}>Create account</Text>
            </PressableScale>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>

      <Modal transparent visible={resetOpen} statusBarTranslucent animationType="fade" onRequestClose={() => setResetOpen(false)}>
        <View style={[styles.modalScrim, { backgroundColor: palette.scrim }]}>
          <GlassCard animate={false} padding={22} style={{ marginHorizontal: 32 }}>
            <Text style={type.headingSmall(palette.text)}>Reset password</Text>
            {resetSent ? (
              <>
                <Text style={[type.body(palette.textBody), { marginTop: 10 }]}>
                  Check your inbox for the reset link.
                </Text>
                <View style={{ marginTop: 18 }}>
                  <Button label="Back to Sign In" variant="outline" onPress={() => setResetOpen(false)} />
                </View>
              </>
            ) : (
              <>
                <Text style={[type.body(palette.textSecondary), { marginTop: 8 }]}>
                  We'll email you a secure reset link.
                </Text>
                <View style={{ marginTop: 14 }}>
                  <Input
                    label="Email"
                    placeholder="you@example.com"
                    autoCapitalize="none"
                    keyboardType="email-address"
                    value={resetEmail}
                    onChangeText={setResetEmail}
                  />
                </View>
                <View style={{ marginTop: 16, gap: 10 }}>
                  <Button label="Send Reset Link" onPress={sendReset} disabled={!resetEmail.includes('@')} />
                  <Button label="Cancel" variant="ghost" onPress={() => setResetOpen(false)} />
                </View>
              </>
            )}
          </GlassCard>
        </View>
      </Modal>
    </View>
  );
}

export default function Login() {
  return <LoginInner />;
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, justifyContent: 'center', padding: 20 },
  header: { alignItems: 'center', gap: 6 },
  arabic: { fontFamily: FONT_ARABIC_BOLD, fontSize: 60, lineHeight: 94, marginBottom: 2 },
  error: {
    borderWidth: 1,
    padding: 12,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 24,
  },
  modalScrim: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
