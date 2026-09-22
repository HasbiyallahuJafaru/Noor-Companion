import React, { useMemo, useRef, useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTheme } from '../../src/theme';
import { Button, Card, PressableScale } from '../../src/components';
import { InterventionShell } from '../../src/components/shared/InterventionShell';
import { INTERVENTION_TASKS } from '../../src/lib/types';
import { haptic } from '../../src/lib/haptics';
import { mmss } from '../../src/lib/format';

/** Step 3: one grounding task. Timed tasks run a countdown; others finish on "I did it". */
export default function InterventionTask() {
  const { palette, type, radius } = useTheme();
  const task = useMemo(() => INTERVENTION_TASKS[Math.floor(Math.random() * INTERVENTION_TASKS.length)]!, []);
  const timed = task.type === 'timed' && !!task.durationSeconds;
  const [remaining, setRemaining] = useState(task.durationSeconds ?? 0);
  const done = useRef(false);

  useEffect(() => {
    if (!timed) return;
    const id = setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          clearInterval(id);
          if (!done.current) {
            done.current = true;
            haptic.heavy();
          }
          return 0;
        }
        return r - 1;
      });
    }, 1000);
    return () => clearInterval(id);
  }, [timed]);

  const progress = timed && task.durationSeconds ? 1 - remaining / task.durationSeconds : 1;
  const finished = timed ? remaining === 0 : false;

  return (
    <InterventionShell step={3}>
      <View style={styles.fill}>
        <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
          <Text style={type.heading(palette.text)}>{task.label}</Text>
          <Text style={[type.body(palette.textSecondary), { marginTop: 6 }]}>One small step is enough right now.</Text>

          <View style={[styles.instruction, { backgroundColor: palette.tealSoft, borderRadius: radius.lg }]}>
            <Text style={type.body(palette.textBody)}>{task.instruction}</Text>
          </View>

          {timed && (
            <View style={[styles.timerCard, { backgroundColor: palette.surface, borderRadius: radius.xl }]}>
              <Text style={type.numeral(52, finished ? palette.success : palette.teal)}>{mmss(remaining)}</Text>
              <View style={[styles.timerTrack, { backgroundColor: palette.hairline }]}>
                <View
                  style={[
                    styles.timerFill,
                    {
                      backgroundColor: finished ? palette.success : palette.teal,
                      width: `${Math.round(progress * 100)}%`,
                    },
                  ]}
                />
              </View>
              {!finished && <Text style={type.caption(palette.textMuted)}>Keep going. You are doing well.</Text>}
            </View>
          )}
        </ScrollView>
        <View style={styles.footer}>
          {timed && !finished ? (
            <Button label="Keep Going" variant="ghost" disabled onPress={() => {}} />
          ) : (
            <Button label="I did it" onPress={() => router.push('/intervention/affirm')} />
          )}
        </View>
      </View>
    </InterventionShell>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  scroll: { flexGrow: 1, padding: 24, paddingBottom: 40 },
  instruction: { padding: 20, marginTop: 22 },
  timerCard: {
    alignItems: 'center',
    paddingVertical: 30,
    paddingHorizontal: 24,
    marginTop: 22,
  },
  timerTrack: {
    height: 6,
    borderRadius: 3,
    overflow: 'hidden',
    width: '100%',
    marginTop: 22,
  },
  timerFill: { height: '100%', borderRadius: 3 },
  footer: { paddingHorizontal: 24, paddingBottom: 28 },
});
