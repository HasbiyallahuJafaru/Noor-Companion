import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { LogOut, Moon, Sun, MonitorSmartphone, Flame, CreditCard, ChevronRight, BarChart3, Users, LayoutDashboard } from 'lucide-react-native';
import { useTheme, type ThemeMode } from '../../src/theme';
import { useAuthStore } from '../../src/lib/auth-store';
import { useUiStore } from '../../src/lib/ui-store';
import { Screen, GlassCard, Card, Button, Avatar, Badge, PressableScale } from '../../src/components';
import { haptic } from '../../src/lib/haptics';

const AURORA = require('../../src/components/core/AuroraBackground').AuroraBackground;

export default function ProfileScreen() {
  const { palette, type, radius, shadows } = useTheme();
  const insets = useSafeAreaInsets();
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);
  const themePreference = useUiStore((s) => s.themePreference);
  const setThemePreference = useUiStore((s) => s.setThemePreference);
  const [confirming, setConfirming] = useState(false);

  const roleBadge =
    user?.role === 'admin' ? 'gold' : user?.role === 'therapist' ? 'teal' : 'muted';

  const themeOptions: { id: ThemeMode; label: string; icon: typeof Moon }[] = [
    { id: 'system', label: 'Auto', icon: MonitorSmartphone },
    { id: 'light', label: 'Light', icon: Sun },
    { id: 'dark', label: 'Dark', icon: Moon },
  ];

  const doSignOut = () => {
    Alert.alert('Sign out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign Out',
        style: 'destructive',
        onPress: async () => {
          await signOut();
          router.replace('/(auth)/login');
        },
      },
    ]);
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <ScrollView contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: 140 }} showsVerticalScrollIndicator={false}>
        <Text style={[type.heading(palette.text), styles.title]}>Profile</Text>

        {/* Identity */}
        <AnimatedSection>
          <GlassCard padding={20}>
            <View style={styles.identityRow}>
              <Avatar url={user?.avatarUrl} firstName={user?.firstName ?? ''} lastName={user?.lastName ?? ''} size={72} />
              <View style={{ flex: 1, marginLeft: 16 }}>
                <Text style={type.headingSmall(palette.text)}>
                  {user?.firstName} {user?.lastName}
                </Text>
                <View style={{ marginTop: 6 }}>
                  <Badge label={user?.role ?? 'user'} color={roleBadge as never} />
                </View>
              </View>
            </View>
          </GlassCard>
        </AnimatedSection>

        {/* Info tiles */}
        <View style={styles.tileRow}>
          <PressableScale haptic="light" style={{ flex: 1 }} onPress={() => router.push('/upgrade')}>
            <Card padding={16} style={{ height: 92, justifyContent: 'space-between' }}>
              <View style={[styles.tileIcon, { backgroundColor: palette.goldSoft }]}>
                <CreditCard size={17} color={palette.goldDeep} strokeWidth={1.9} />
              </View>
              <Text style={type.bodySmall(palette.textBody)}>
                Subscription:{' '}
                <Text style={{ fontWeight: '700', color: user?.subscriptionTier === 'paid' ? palette.goldDeep : palette.textSecondary }}>
                  {user?.subscriptionTier === 'paid' ? 'Paid' : 'Free'}
                </Text>
              </Text>
            </Card>
          </PressableScale>
          <PressableScale haptic="light" style={{ flex: 1 }} onPress={() => router.push('/progress')}>
            <Card padding={16} style={{ height: 92, justifyContent: 'space-between' }}>
              <View style={[styles.tileIcon, { backgroundColor: palette.tealSoft }]}>
                <Flame size={17} color={palette.teal} strokeWidth={1.9} />
              </View>
              <Text style={type.bodySmall(palette.textBody)}>
                Streak:{' '}
                <Text style={{ fontWeight: '700', color: palette.tealDeep }}>
                  {(user?.streak?.currentStreak ?? 0)} days
                </Text>
              </Text>
            </Card>
          </PressableScale>
        </View>

        {/* Quick links */}
        {(user?.role === 'therapist' || user?.role === 'admin') && (
          <AnimatedSection>
            <Card style={{ marginTop: 14 }}>
              {user?.role === 'therapist' && (
                <LinkRow icon={LayoutDashboard} label="Therapist Dashboard" onPress={() => router.push('/(tabs)/dashboard')} />
              )}
              {user?.role === 'admin' && (
                <LinkRow icon={Users} label="Admin Panel" onPress={() => router.push('/(tabs)/admin')} />
              )}
            </Card>
          </AnimatedSection>
        )}

        {/* Appearance */}
        <AnimatedSection>
          <Card style={{ marginTop: 14 }}>
            <Text style={[type.caption(palette.textSecondary), { textTransform: 'uppercase', letterSpacing: 0.8, fontSize: 11, marginBottom: 12 }]}>
              Appearance
            </Text>
            <View style={[styles.themeRow, { backgroundColor: palette.backgroundElevated, borderRadius: radius.md }]}>
              {themeOptions.map((o) => {
                const active = themePreference === o.id;
                return (
                  <PressableScale
                    key={o.id}
                    haptic="light"
                    onPress={() => setThemePreference(o.id)}
                    style={[
                      styles.themeOption,
                      {
                        backgroundColor: active ? palette.surface : 'transparent',
                        borderRadius: radius.sm,
                      },
                      active && shadows.sm,
                    ]}
                  >
                    <o.icon size={15} color={active ? palette.teal : palette.textMuted} strokeWidth={1.9} />
                    <Text numberOfLines={1} style={[type.caption(active ? palette.text : palette.textMuted), { fontSize: 11 }]}>{o.label}</Text>
                  </PressableScale>
                );
              })}
            </View>
          </Card>
        </AnimatedSection>

        {/* Sign out */}
        <AnimatedSection>
          <View style={{ marginTop: 20 }}>
            <Button
              label={confirming ? 'Signing out…' : 'Sign Out'}
              variant="outline"
              onPress={doSignOut}
              icon={<LogOut size={17} color={palette.danger} strokeWidth={2} />}
            />
            <Text style={[type.micro(palette.textMuted), styles.versionNote, { textAlign: 'center' }]}>
              Noor Companion · React Native
            </Text>
          </View>
        </AnimatedSection>
      </ScrollView>
    </View>
  );
}

function LinkRow({ icon: Icon, label, onPress }: { icon: typeof Users; label: string; onPress: () => void }) {
  const { palette, type } = useTheme();
  return (
    <PressableScale haptic="light" onPress={onPress} style={{ paddingVertical: 4 }}>
      <View style={styles.linkRow}>
        <Icon size={18} color={palette.teal} strokeWidth={1.9} />
        <Text style={[type.body(palette.textBody), { flex: 1, marginLeft: 12 }]}>{label}</Text>
        <ChevronRight size={18} color={palette.textMuted} strokeWidth={2} />
      </View>
    </PressableScale>
  );
}

function AnimatedSection({ children }: { children: React.ReactNode }) {
  const Fade = require('react-native-reanimated').FadeInDown;
  const AnimatedView = require('react-native-reanimated').default.View;
  return (
    <AnimatedView entering={Fade.delay(60).springify().damping(18)} style={{ marginTop: 14 }}>
      {children}
    </AnimatedView>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  title: { paddingHorizontal: 20, marginBottom: 18 },
  identityRow: { flexDirection: 'row', alignItems: 'center' },
  tileRow: { flexDirection: 'row', gap: 12, paddingHorizontal: 20, marginTop: 14 },
  tileIcon: {
    width: 34,
    height: 34,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  themeRow: { flexDirection: 'row', padding: 4, gap: 4 },
  themeOption: {
    flex: 1,
    minWidth: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    paddingHorizontal: 6,
  },
  linkRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10 },
  versionNote: { marginTop: 18 },
});
