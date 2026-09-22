import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { Screen, Input, Button, Skeleton, ErrorState } from '../../src/components';

export default function EditTherapistProfile() {
  const { palette, type, radius } = useTheme();
  const qc = useQueryClient();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loadError, setLoadError] = useState(false);
  const [form, setForm] = useState({
    bio: '',
    specialisations: '',
    qualifications: '',
    languagesSpoken: '',
    yearsExperience: '',
    sessionRateNgn: '',
  });

  useEffect(() => {
    (async () => {
      try {
        const p = await api.myTherapistProfile();
        setForm({
          bio: p.bio ?? '',
          specialisations: (p.specialisations ?? []).join(', '),
          qualifications: (p.qualifications ?? []).join(', '),
          languagesSpoken: (p.languagesSpoken ?? []).join(', '),
          yearsExperience: String(p.yearsExperience ?? ''),
          sessionRateNgn: String(p.sessionRateNgn ?? ''),
        });
      } catch {
        setLoadError(true);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const save = async () => {
    if (!form.bio.trim() || !form.specialisations.trim() || !form.languagesSpoken.trim()) {
      setError('Bio, specialisations and languages are required.');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      await api.saveTherapistProfile({
        bio: form.bio.trim(),
        specialisations: form.specialisations.split(',').map((s) => s.trim()).filter(Boolean),
        qualifications: form.qualifications.split(',').map((s) => s.trim()).filter(Boolean),
        languagesSpoken: form.languagesSpoken.split(',').map((s) => s.trim()).filter(Boolean),
        yearsExperience: parseInt(form.yearsExperience, 10) || 0,
        sessionRateNgn: parseInt(form.sessionRateNgn, 10) || 0,
      });
      qc.invalidateQueries({ queryKey: ['therapist-me'] });
      Alert.alert('Saved', 'Your profile has been updated.');
      router.back();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not save profile');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Screen back title="Edit Profile">
        <View style={{ padding: 20, gap: 14 }}>
          <Skeleton height={120} radius={radius.lg} />
          <Skeleton height={54} radius={radius.md} />
          <Skeleton height={54} radius={radius.md} />
        </View>
      </Screen>
    );
  }
  if (loadError) {
    return (
      <Screen back title="Edit Profile">
        <ErrorState onRetry={() => router.replace('/therapist/edit-profile')} />
      </Screen>
    );
  }

  const set = (k: keyof typeof form) => (v: string) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <Screen
      back
      title="Edit Profile"
      bottom={<Button label={saving ? 'Saving…' : 'Save Profile'} onPress={save} loading={saving} />}
    >
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <Input label="Bio" placeholder="Tell clients about your approach" value={form.bio} onChangeText={set('bio')} multiline />
        <Input
          label="Specialisations"
          placeholder="Anxiety, Addiction, Trauma"
          value={form.specialisations}
          onChangeText={set('specialisations')}
          hint="Comma-separated"
        />
        <Input
          label="Qualifications"
          placeholder="MSc Clinical Psychology, …"
          value={form.qualifications}
          onChangeText={set('qualifications')}
          hint="Comma-separated, optional"
        />
        <Input
          label="Languages"
          placeholder="English, Hausa"
          value={form.languagesSpoken}
          onChangeText={set('languagesSpoken')}
          hint="Comma-separated"
        />
        <View style={styles.numRow}>
          <Input label="Years Experience" placeholder="5" value={form.yearsExperience} onChangeText={set('yearsExperience')} keyboardType="number-pad" style={{ flex: 1 }} />
          <Input label="Rate (₦ per session)" placeholder="5000" value={form.sessionRateNgn} onChangeText={set('sessionRateNgn')} keyboardType="number-pad" style={{ flex: 1 }} />
        </View>
        {error && (
          <View style={[styles.error, { backgroundColor: palette.dangerSoft, borderRadius: radius.md }]}>
            <Text style={type.bodySmall(palette.danger)}>{error}</Text>
          </View>
        )}
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, gap: 16, paddingBottom: 40 },
  numRow: { flexDirection: 'row', gap: 12 },
  error: { padding: 12 },
});
