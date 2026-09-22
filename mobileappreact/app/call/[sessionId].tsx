import React, { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Mic, MicOff, Volume2, VolumeX, PhoneOff } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withSequence,
  withTiming,
  interpolate,
  Easing,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { useTheme } from '../../src/theme';
import { PressableScale } from '../../src/components';
import { api } from '../../src/lib/api';
import { haptic } from '../../src/lib/haptics';
import { getCallingEngine, type CallPhase } from '../../src/lib/calling';

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

/**
 * Live session screen. Status mirrors the Flutter calling flow:
 * Connecting → Waiting for therapist → active (timer) → end → rating.
 */
export default function CallScreen() {
  const { palette, type, radius, shadows } = useTheme();
  const insets = useSafeAreaInsets();
  const { sessionId, channelName, agoraToken, therapistName, therapistId } = useLocalSearchParams<{
    sessionId: string;
    channelName: string;
    agoraToken: string;
    therapistName: string;
    therapistId: string;
  }>();

  const [phase, setPhase] = useState<CallPhase>('connecting');
  const [seconds, setSeconds] = useState(0);
  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const endedRef = useRef(false);

  const engine = getCallingEngine();

  // Connection sequence: simulated engine reaches "active" after ~4s.
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        await engine.join({ sessionId, channelName, agoraToken, therapistName, therapistId } as never);
        if (!alive) return;
        setPhase('ringing');
        setTimeout(() => alive && setPhase('active'), 2500);
      } catch (e) {
        if (alive) {
          setPhase('error');
          setError(e instanceof Error ? e.message : 'Connection failed');
        }
      }
    })();
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Session timer.
  useEffect(() => {
    if (phase !== 'active') return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, [phase]);

  // Orb animation: gentle breathing + slow rotation.
  const pulse = useSharedValue(1);
  const rotate = useSharedValue(0);
  useEffect(() => {
    pulse.value = withRepeat(
      withSequence(withTiming(1.05, { duration: 1500, easing: Easing.inOut(Easing.sin) }), withTiming(1, { duration: 1500, easing: Easing.inOut(Easing.sin) })),
      -1,
    );
    rotate.value = withRepeat(withTiming(360, { duration: 8000, easing: Easing.linear }), -1);
    return () => {
      pulse.value = 1;
    };
  }, [pulse, rotate]);

  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulse.value }],
  }));
  const rotateStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${rotate.value}deg` }],
  }));
  const glowStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pulse.value, [1, 1.05], [1, 1.14]) }],
    opacity: interpolate(pulse.value, [1, 1.05], [0.5, 0.85]),
  }));

  const endCall = async () => {
    if (endedRef.current) return;
    endedRef.current = true;
    haptic.heavy();
    try {
      await engine.leave();
      await api.endCall(String(sessionId));
    } catch {
      // proceed to rating regardless
    }
    router.replace({
      pathname: '/call-rating',
      params: { sessionId: String(sessionId), therapistName: String(therapistName ?? ''), duration: String(seconds) },
    });
  };

  useEffect(() => () => {
    if (!endedRef.current) api.endCall(String(sessionId)).catch(() => {});
  }, [sessionId]);

  const toggleMute = async () => {
    haptic.light();
    setMuted((m) => {
      engine.mute(!m);
      return !m;
    });
  };
  const toggleSpeaker = async () => {
    haptic.light();
    setSpeaker((s) => {
      engine.speaker(!s);
      return !s;
    });
  };

  const statusLine =
    phase === 'connecting'
      ? 'Connecting…'
      : phase === 'ringing'
        ? 'Waiting for therapist…'
        : phase === 'active'
          ? fmt(seconds)
          : 'Connection error';

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top + 10, paddingBottom: insets.bottom + 24 }]}>
      <AURORA />
      <Text style={[type.headingSmall(palette.text), { textAlign: 'center' }]}>{therapistName}</Text>
      <Text style={[type.body(palette.textSecondary), { textAlign: 'center', marginTop: 6, color: phase === 'active' ? palette.teal : palette.textSecondary }]}>
        {statusLine}
      </Text>

      <View style={styles.orbHost}>
        <Animated.View style={[styles.orbGlow, { backgroundColor: `${palette.teal}33` }, glowStyle]} />
        <Animated.View style={[styles.orb, pulseStyle]}>
          <Animated.View style={[styles.orbRing, rotateStyle]}>
            <LinearGradient
              colors={[palette.tealDeep, palette.teal, palette.gold, palette.tealDeep]}
              locations={[0, 0.35, 0.7, 1]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
          </Animated.View>
          <View style={[styles.orbInner, { backgroundColor: palette.isDark ? 'rgba(10,12,26,0.55)' : 'rgba(255,255,255,0.55)' }]}>
            <Text style={type.numeral(34, phase === 'active' ? palette.text : palette.textMuted)}>
              {phase === 'active' ? fmt(seconds) : '•••'}
            </Text>
          </View>
        </Animated.View>
      </View>

      {error && (
        <Text style={[type.bodySmall(palette.danger), { textAlign: 'center', marginBottom: 12 }]}>{error}</Text>
      )}

      <View style={styles.controls}>
        <ControlButton onPress={toggleMute} active={!muted}>
          {muted ? <MicOff size={22} color={palette.text} strokeWidth={1.9} /> : <Mic size={22} color={palette.text} strokeWidth={1.9} />}
        </ControlButton>
        <PressableScale haptic="heavy" pressScale={0.92} onPress={endCall} style={[styles.endBtn, shadows.md]}>
          <PhoneOff size={26} color="#FFFFFF" strokeWidth={2.2} />
        </PressableScale>
        <ControlButton onPress={toggleSpeaker} active={speaker}>
          {speaker ? <Volume2 size={22} color={palette.text} strokeWidth={1.9} /> : <VolumeX size={22} color={palette.text} strokeWidth={1.9} />}
        </ControlButton>
      </View>
    </View>
  );
}

function ControlButton({ children, onPress, active = true }: { children: React.ReactNode; onPress: () => void; active?: boolean }) {
  const { palette, radius } = useTheme();
  return (
    <PressableScale haptic="light" onPress={onPress} style={[styles.control, { backgroundColor: palette.surface, borderColor: palette.border, borderRadius: radius.pill, opacity: active ? 1 : 0.75 }]}>
      {children}
    </PressableScale>
  );
}

function fmt(s: number) {
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  orbHost: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  orbGlow: {
    position: 'absolute',
    width: 260,
    height: 260,
    borderRadius: 130,
  },
  orb: {
    width: 220,
    height: 220,
    alignItems: 'center',
    justifyContent: 'center',
  },
  orbRing: {
    position: 'absolute',
    width: 220,
    height: 220,
    borderRadius: 110,
    overflow: 'hidden',
  },
  orbInner: {
    width: 196,
    height: 196,
    borderRadius: 98,
    alignItems: 'center',
    justifyContent: 'center',
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 26,
  },
  control: {
    width: 58,
    height: 58,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  endBtn: {
    width: 68,
    height: 68,
    borderRadius: 34,
    backgroundColor: '#D63031',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
