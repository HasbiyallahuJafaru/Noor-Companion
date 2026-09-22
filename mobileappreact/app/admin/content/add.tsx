import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { router } from 'expo-router';
import { Sparkles, HandHeart, BookOpen } from 'lucide-react-native';
import { useTheme } from '../../../src/theme';
import { api } from '../../../src/lib/api';
import { Screen, Input, Button, PressableScale } from '../../../src/components';
import { haptic } from '../../../src/lib/haptics';

const CATEGORIES = [
  { id: 'dhikr', label: 'Dhikr', icon: Sparkles },
  { id: 'duas', label: 'Dua', icon: HandHeart },
  { id: 'recitations', label: 'Recitation', icon: BookOpen },
];

export default function AdminContentAdd() {
  const { palette, type, radius, shadows } = useTheme();
  const [category, setCategory] = useState('dhikr');
  const [form, setForm] = useState({
    title: '',
    arabicText: '',
    transliteration: '',
    translation: '',
    tags: '',
    audioUrl: '',
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const set = (k: keyof typeof form) => (v: string) => setForm((f) => ({ ...f, [k]: v }));

  const save = async () => {
    if (!form.title.trim() || !form.arabicText.trim() || !form.translation.trim() || !form.tags.trim()) {
      setError('Title, Arabic, translation and at least one tag are required.');
      return;
    }
    if (form.audioUrl && !/^https?:\/\//.test(form.audioUrl.trim())) {
      setError('Audio URL must start with http(s)://');
      return;
    }
    setError(null);
    setSaving(true);
    try {
      await api.adminAddContent({
        title: form.title.trim(),
        arabicText: form.arabicText.trim(),
        transliteration: form.transliteration.trim(),
        translation: form.translation.trim(),
        category,
        tags: form.tags.split(',').map((t) => t.trim().toLowerCase()).filter(Boolean),
        audioUrl: form.audioUrl.trim() || undefined,
        sortOrder: 0,
      });
      haptic.success();
      Alert.alert('Content added', 'The new item is now in the library.');
      router.back();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not save content');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Screen
      back
      title="Add Content"
      bottom={<Button label={saving ? 'Saving…' : 'Add to Library'} onPress={save} loading={saving} />}
    >
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <Text style={[type.caption(palette.textSecondary), { textTransform: 'uppercase', letterSpacing: 0.8, fontSize: 11 }]}>
          Category
        </Text>
        <View style={styles.catRow}>
          {CATEGORIES.map((c) => {
            const active = category === c.id;
            return (
              <PressableScale key={c.id} haptic="light" onPress={() => setCategory(c.id)} style={{ flex: 1 }}>
                <View
                  style={[
                    styles.catTile,
                    {
                      backgroundColor: active ? palette.tealSoft : palette.surface,
                      borderColor: active ? palette.teal : palette.border,
                      borderRadius: radius.md,
                    },
                    active && shadows.sm,
                  ]}
                >
                  <c.icon size={19} color={active ? palette.teal : palette.textMuted} strokeWidth={1.9} />
                  <Text style={[type.caption(active ? palette.tealDeep : palette.textMuted), { marginTop: 7 }]}>
                    {c.label}
                  </Text>
                </View>
              </PressableScale>
            );
          })}
        </View>

        <Input label="Title" placeholder="e.g. Morning Dhikr" value={form.title} onChangeText={set('title')} />
        <Input
          label="Arabic Text"
          placeholder="النص العربي"
          value={form.arabicText}
          onChangeText={set('arabicText')}
          multiline
        />
        <Input label="Transliteration" placeholder="Optional" value={form.transliteration} onChangeText={set('transliteration')} multiline />
        <Input label="Translation" placeholder="English meaning" value={form.translation} onChangeText={set('translation')} multiline />
        <Input label="Tags" placeholder="morning, forgiveness" value={form.tags} onChangeText={set('tags')} hint="Comma-separated" />
        <Input label="Audio URL" placeholder="https://… (optional)" value={form.audioUrl} onChangeText={set('audioUrl')} autoCapitalize="none" />
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
  catRow: { flexDirection: 'row', gap: 12, marginTop: 10 },
  catTile: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    paddingVertical: 18,
  },
  error: { padding: 12 },
});
