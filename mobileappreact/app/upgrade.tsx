import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Linking, AppState, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { LinearGradient } from 'expo-linear-gradient';
import { Phone, ShieldCheck, Star, Sparkles, Crown } from 'lucide-react-native';
import { useTheme } from '../src/theme';
import { api } from '../src/lib/api';
import { useAuthStore } from '../src/lib/auth-store';
import { Screen, GlassCard, Button, Confetti } from '../src/components';
import { config } from '../src/lib/config';
import { haptic } from '../src/lib/haptics';

const FEATURES = [
  { icon: Phone, title: 'Unlimited voice sessions', body: 'Speak with any available therapist, whenever you need.' },
  { icon: ShieldCheck, title: 'Verified professionals', body: 'Every therapist is reviewed and approved by our team.' },
  { icon: Star, title: 'Rate & bookmark', body: 'Shape the community and keep your favourite duas close.' },
  { icon: Sparkles, title: 'Premium content', body: 'Extended dhikr and dua library with audio.' },
];

export default function UpgradeScreen() {
  const { palette, type, radius } = useTheme();
  const user = useAuthStore((s) => s.user);
  const refreshUser = useAuthStore((s) => s.refreshUser);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [confirming, setConfirming] = useState(false);

  const startCheckout = async () => {
    setError(null);
    setLoading(true);
    if (config.demoMode) {
      setConfirming(true);
      setTimeout(() => {
        setLoading(false);
        setConfirming(false);
        haptic.success();
        setSuccess(true);
      }, 2600);
      return;
    }
    try {
      const res = await api.subscribeToken();
      const url = res.redirectUrl;
      if (!url) throw new Error('Payment link unavailable');
      haptic.medium();
      if (process.env.EXPO_PUBLIC_FORCE_BROWSER === '1') {
        await Linking.openURL(url);
      } else {
        // In-app browser on both platforms; the backend redirects back to the
        // site on success. Poll /users/me for the tier flip.
        setConfirming(true);
        WebBrowser.openBrowserAsync(url)
          .catch(() => {})
          .finally(() => {
            pollForActivation();
          });
        pollForActivation();
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not start checkout');
      setLoading(false);
      setConfirming(false);
    }
  };

  const pollForActivation = () => {
    let attempts = 0;
    const id = setInterval(async () => {
      attempts += 1;
      await refreshUser();
      if (useAuthStore.getState().user?.subscriptionTier === 'paid') {
        clearInterval(id);
        setLoading(false);
        setConfirming(false);
        haptic.success();
        setSuccess(true);
      } else if (attempts >= 15) {
        clearInterval(id);
        setLoading(false);
        setConfirming(false);
      }
    }, 2000);
  };

  if (success || user?.subscriptionTier === 'paid') {
    return (
      <Screen chrome close onClose={() => router.replace('/(tabs)')}>
        <View style={styles.successWrap}>
          <Confetti />
          <View style={[styles.crownBadge, { backgroundColor: palette.goldSoft }]}>
            <Crown size={34} color={palette.gold} strokeWidth={1.75} />
          </View>
          <Text style={[type.heading(palette.text), { textAlign: 'center', marginTop: 20 }]}>
            Welcome to Premium!
          </Text>
          <Text style={[type.body(palette.textSecondary), { textAlign: 'center', marginTop: 8 }]}>
            Your subscription is active. Barakallahu feek.
          </Text>
          <View style={{ marginTop: 30 }}>
            <Button label="Start Exploring" onPress={() => router.replace('/(tabs)')} />
          </View>
        </View>
      </Screen>
    );
  }

  return (
    <Screen chrome close onClose={() => router.replace('/(tabs)')}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false} bounces={false}>
        <View style={styles.badgeRow}>
          <View style={[styles.premiumPill, { backgroundColor: palette.goldSoft }]}>
            <Crown size={13} color={palette.goldDeep} strokeWidth={2} />
            <Text style={[type.micro(palette.goldDeep), { marginLeft: 6, letterSpacing: 1.2 }]}>PREMIUM</Text>
          </View>
        </View>
        <Text style={[type.heading(palette.text), { textAlign: 'center' }]}>Unlock Noor Companion Premium</Text>
        <Text style={[type.body(palette.textSecondary), { textAlign: 'center', marginTop: 8, paddingHorizontal: 20 }]}>
          Everything you need for the journey, in one plan.
        </Text>

        <GlassCard animate={false} padding={0} style={{ marginTop: 26, overflow: 'hidden', borderWidth: 0 }}>
          <LinearGradient colors={[palette.teal, palette.tealDeep]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
            <View style={styles.priceCard}>
              <Text style={type.body('#D9F3F0')}>Monthly</Text>
              <View style={styles.priceRow}>
                <Text style={[type.numeral(44, '#FFFFFF'), { marginTop: 6 }]}>₦{config.monthlyPriceNgn.toLocaleString()}</Text>
                <Text style={[type.body('#D9F3F0'), { marginLeft: 8, marginTop: 18 }]}>/ month</Text>
              </View>
            </View>
          </LinearGradient>
        </GlassCard>

        <View style={styles.featureList}>
          {FEATURES.map((f, i) => (
            <GlassCard key={f.title} index={i} padding={16} style={{ backgroundColor: palette.surfaceGlass }}>
              <View style={styles.featureRow}>
                <View style={[styles.featureIcon, { backgroundColor: palette.tealSoft }]}>
                  <f.icon size={18} color={palette.teal} strokeWidth={1.9} />
                </View>
                <View style={{ flex: 1, marginLeft: 14 }}>
                  <Text style={type.headingSmall(palette.text)}>{f.title}</Text>
                  <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 2 }]}>{f.body}</Text>
                </View>
              </View>
            </GlassCard>
          ))}
        </View>

        {error && (
          <View style={[styles.error, { backgroundColor: palette.dangerSoft, borderRadius: radius.md }]}>
            <Text style={type.bodySmall(palette.danger)}>{error}</Text>
          </View>
        )}

        {confirming && (
          <View style={[styles.confirming, { borderRadius: radius.lg }]}>
            <ActivityIndicator color={palette.teal} />
            <Text style={[type.bodySmall(palette.textSecondary), { marginLeft: 10 }]}>Confirming your payment…</Text>
          </View>
        )}
      </ScrollView>

      <View style={styles.ctaHost}>
        <Button label={`Upgrade Now — ₦${config.monthlyPriceNgn.toLocaleString()}/month`} variant="gold" onPress={startCheckout} loading={loading} />
        <Text style={[type.micro(palette.textMuted), { textAlign: 'center', marginTop: 10 }]}>
          Cancel any time. Billed monthly.
        </Text>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, paddingBottom: 12 },
  successWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
  crownBadge: { width: 84, height: 84, borderRadius: 42, alignItems: 'center', justifyContent: 'center' },
  badgeRow: { alignItems: 'center', marginTop: 8 },
  premiumPill: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 999,
  },
  priceCard: { padding: 24 },
  priceRow: { flexDirection: 'row', alignItems: 'flex-start' },
  featureList: { gap: 10, marginTop: 18 },
  featureRow: { flexDirection: 'row', alignItems: 'center' },
  featureIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  error: { padding: 12, marginTop: 14 },
  confirming: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 14,
    marginTop: 14,
    backgroundColor: 'rgba(13,148,136,0.08)',
  },
  ctaHost: { paddingHorizontal: 20, paddingBottom: 8 },
});
