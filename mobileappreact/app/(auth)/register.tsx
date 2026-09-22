import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { router } from 'expo-router';
import { supabase } from '../../src/lib/supabase';
import { useTheme } from '../../src/theme';
import { AppBackground } from '../../src/components/core/AppBackground';
import { GlassCard, Input, Button, PressableScale, Chip } from '../../src/components';

export default function Register() {
  const { palette, type, radius } = useTheme();
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'user' | 'therapist'>('user');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [needsConfirmation, setNeedsConfirmation] = useState(false);

  const signUp = async () => {
    setError(null);
    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }
    setLoading(true);
    try {
      const { data, error: err } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            first_name: firstName.trim(),
            last_name: lastName.trim(),
            role,
          },
        },
      });
      if (err) throw err;
      if (data.session) {
        router.replace('/(tabs)');
      } else {
        setNeedsConfirmation(true);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not create account');
    } finally {
      setLoading(false);
    }
  };

  if (needsConfirmation) {
    return (
      <View style={[styles.fill, { backgroundColor: palette.background }]}>
        <AppBackground variant="sanctuary" />
        <View style={styles.centerWrap}>
          <GlassCard animate={false} padding={24}>
            <Text style={type.heading(palette.text)}>Check your email</Text>
            <Text style={[type.body(palette.textBody), { marginTop: 8 }]}>
              We sent a confirmation link to {email.trim()}. Confirm to activate your account.
            </Text>
            <View style={{ marginTop: 20 }}>
              <Button label="Go to Sign In" onPress={() => router.replace('/(auth)/login')} />
            </View>
          </GlassCard>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AppBackground variant="sanctuary" />
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.fill}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled" bounces={false}>
          <View style={styles.header}>
            <Text style={type.heading(palette.text)}>Bismillah</Text>
            <Text style={type.body(palette.textSecondary)}>Create your account</Text>
          </View>

          <GlassCard index={1} padding={22} style={{ marginTop: 26 }}>
            <View style={{ gap: 16 }}>
              <View style={styles.nameRow}>
                <Input label="First Name" placeholder="Aisha" value={firstName} onChangeText={setFirstName} style={{ flex: 1 }} />
                <Input label="Last Name" placeholder="Rahman" value={lastName} onChangeText={setLastName} style={{ flex: 1 }} />
              </View>
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
                placeholder="Minimum 8 characters"
                secure
                value={password}
                onChangeText={setPassword}
                hint="At least 8 characters."
              />
              <View>
                <Text style={[type.caption(palette.textSecondary), { marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.8, fontSize: 11 }]}>
                  I am joining as
                </Text>
                <View style={styles.chipRow}>
                  <Chip label="Daily user" selected={role === 'user'} onPress={() => setRole('user')} />
                  <Chip label="Therapist" selected={role === 'therapist'} onPress={() => setRole('therapist')} />
                </View>
              </View>
              {error && (
                <View
                  style={[
                    styles.error,
                    { backgroundColor: palette.dangerSoft, borderRadius: radius.md, borderColor: palette.danger },
                  ]}
                >
                  <Text style={type.bodySmall(palette.danger)}>{error}</Text>
                </View>
              )}
              <Button
                label="Create Account"
                onPress={signUp}
                loading={loading}
                disabled={!firstName || !lastName || !email.includes('@') || password.length < 8}
              />
            </View>
          </GlassCard>

          <View style={styles.footer}>
            <Text style={type.bodySmall(palette.textSecondary)}>Already have an account? </Text>
            <PressableScale haptic="light" onPress={() => router.push('/(auth)/login')}>
              <Text style={[type.bodySmall(palette.teal), { fontWeight: '700' }]}>Sign in</Text>
            </PressableScale>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, justifyContent: 'center', padding: 20 },
  header: { alignItems: 'center', gap: 4 },
  nameRow: { flexDirection: 'row', gap: 12 },
  chipRow: { flexDirection: 'row', gap: 10 },
  error: { borderWidth: 1, padding: 12 },
  footer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 24 },
  centerWrap: { flex: 1, justifyContent: 'center', padding: 24 },
});
