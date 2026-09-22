import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useQueryClient } from '@tanstack/react-query';
import { useTheme } from '../src/theme';
import { api } from '../src/lib/api';
import { Screen, Button, StarRating, PressableScale } from '../src/components';
import { formatDuration } from '../src/lib/format';
import { haptic } from '../src/lib/haptics';

export default function CallRating() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const { sessionId, therapistName, duration } = useLocalSearchParams<{
    sessionId: string;
    therapistName?: string;
    duration?: string;
  }>();
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const qc = useQueryClient();

  const finish = async (withRating: boolean) => {
    if (withRating && rating === 0) return;
    setSubmitting(true);
    try {
      if (withRating) await api.rateCall(String(sessionId), rating, comment.trim() || undefined);
      qc.invalidateQueries({ queryKey: ['notifications'] });
    } catch {
      // rating is best-effort; return home regardless
    }
    haptic.medium();
    router.replace('/(tabs)');
  };

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top + 20, paddingBottom: insets.bottom + 24 }]}>
      <AURORA />
      <View style={styles.center}>
        <Text style={type.heading(palette.text)}>Call Ended</Text>
        <Text style={[type.body(palette.textSecondary), { marginTop: 8, textAlign: 'center' }]}>
          Session with {therapistName}
          {duration ? ` · ${formatDuration(parseInt(String(duration), 10) || 0)}` : ''}
        </Text>

        <View style={[styles.card, { backgroundColor: palette.surface, borderRadius: radius.xl, borderColor: palette.border }]}>
          <Text style={[type.caption(palette.textSecondary), { textTransform: 'uppercase', letterSpacing: 0.8 }]}>
            How was your session?
          </Text>
          <View style={{ alignItems: 'center', marginTop: 18 }}>
            <StarRating value={rating} size={40} interactive onRate={setRating} />
          </View>
          <TextInput
            placeholder="Anything you'd like to share? (optional)"
            placeholderTextColor={palette.textMuted}
            value={comment}
            onChangeText={setComment}
            multiline
            maxLength={500}
            style={[
              type.body(palette.text),
              styles.comment,
              { backgroundColor: palette.backgroundElevated, borderRadius: radius.md, borderColor: palette.border },
            ]}
          />
        </View>

        <View style={styles.ctaStack}>
          <Button label={submitting ? 'Submitting…' : 'Submit Rating'} onPress={() => finish(true)} disabled={rating === 0 || submitting} loading={submitting} />
          <Button label="Skip" variant="ghost" onPress={() => finish(false)} disabled={submitting} />
        </View>
        <PressableScale haptic="light" onPress={() => finish(false)}>
          <Text style={[type.micro(palette.textMuted), { marginTop: 8 }]}>Your feedback helps other users</Text>
        </PressableScale>
      </View>
    </View>
  );
}

const AURORA = require('../src/components/core/AppBackground').AppBackground;

const styles = StyleSheet.create({
  fill: { flex: 1 },
  center: { flex: 1, padding: 24, justifyContent: 'center' },
  card: {
    borderWidth: 1,
    padding: 22,
    marginTop: 28,
  },
  comment: {
    marginTop: 18,
    minHeight: 90,
    borderWidth: 1,
    padding: 14,
    textAlignVertical: 'top',
  },
  ctaStack: { gap: 10, marginTop: 24 },
});
