import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { CheckCircle2, Send } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../src/theme';
import { api } from '../../src/lib/api';
import { Screen, GlassCard, Input, Button, Chip } from '../../src/components';
import { haptic } from '../../src/lib/haptics';

const TARGETS = [
  { id: 'user', label: 'Users' },
  { id: 'therapist', label: 'Therapists' },
  { id: 'admin', label: 'Admins' },
];

export default function AdminBroadcast() {
  const { palette, type, radius } = useTheme();
  const [target, setTarget] = useState('user');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState<number | null>(null);

  const send = () => {
    if (!title.trim() || !body.trim()) {
      setError('Title and body are required.');
      return;
    }
    Alert.alert('Send broadcast', 'This notification cannot be undone. Send it now?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Send',
        style: 'destructive',
        onPress: async () => {
          setError(null);
          setSending(true);
          try {
            const res = await api.adminBroadcast({
              title: title.trim(),
              body: body.trim(),
              targetRole: target,
            });
            haptic.success();
            setSent(res.sent ?? 0);
          } catch (e) {
            setError(e instanceof Error ? e.message : 'Broadcast failed');
          } finally {
            setSending(false);
          }
        },
      },
    ]);
  };

  if (sent !== null) {
    return (
      <Screen back title="Broadcast">
        <View style={styles.successWrap}>
          <View style={[styles.successIcon, { backgroundColor: palette.successSoft }]}>
            <CheckCircle2 size={38} color={palette.success} strokeWidth={1.75} />
          </View>
          <Text style={[type.heading(palette.text), { textAlign: 'center', marginTop: 20 }]}>
            Broadcast delivered!
          </Text>
          <Text style={[type.body(palette.textSecondary), { textAlign: 'center', marginTop: 8 }]}>
            Notification sent to {sent} device(s).
          </Text>
          <View style={{ marginTop: 28, alignSelf: 'stretch' }}>
            <Button
              label="Send Another"
              variant="outline"
              onPress={() => {
                setSent(null);
                setTitle('');
                setBody('');
              }}
            />
          </View>
        </View>
      </Screen>
    );
  }

  return (
    <Screen back title="Broadcast" bottom={<Button label={sending ? 'Sending…' : 'Send Broadcast'} onPress={send} loading={sending} />}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <GlassCard animate={false} padding={16} style={{ backgroundColor: `${palette.purple}14` }}>
          <View style={styles.infoRow}>
            <Send size={16} color={palette.purple} strokeWidth={2} />
            <Text style={[type.bodySmall(palette.textBody), { flex: 1, marginLeft: 10 }]}>
              Push notification to every device matching the target role.
            </Text>
          </View>
        </GlassCard>

        <View>
          <Text style={[type.caption(palette.textSecondary), styles.label]}>TARGET ROLE</Text>
          <View style={styles.chipRow}>
            {TARGETS.map((t) => (
              <Chip key={t.id} label={t.label} selected={target === t.id} onPress={() => setTarget(t.id)} />
            ))}
          </View>
        </View>

        <Input label="Title" placeholder="e.g. Scheduled maintenance" value={title} onChangeText={setTitle} />
        <Input label="Body" placeholder="Message content…" value={body} onChangeText={setBody} multiline />

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
  infoRow: { flexDirection: 'row', alignItems: 'center' },
  label: { textTransform: 'uppercase', letterSpacing: 0.8, fontSize: 11, marginBottom: 10 },
  chipRow: { flexDirection: 'row', gap: 10 },
  error: { padding: 12 },
  successWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 28 },
  successIcon: { width: 84, height: 84, borderRadius: 42, alignItems: 'center', justifyContent: 'center' },
});
