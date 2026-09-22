import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Phone, PhoneOff } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withSequence,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { Avatar, PressableScale } from '../src/components';
import { api } from '../src/lib/api';
import { haptic } from '../src/lib/haptics';

/** Therapist-side incoming call: pulsing avatar, decline / accept. */
export default function IncomingCall() {
  const insets = useSafeAreaInsets();
  const { sessionId, channelName, agoraToken, callerName } = useLocalSearchParams<{
    sessionId: string;
    channelName?: string;
    agoraToken?: string;
    callerName?: string;
  }>();
  const [accepting, setAccepting] = useState(false);

  const ring = useSharedValue(1);
  useEffect(() => {
    ring.value = withRepeat(
      withSequence(
        withTiming(1.1, { duration: 900, easing: Easing.inOut(Easing.sin) }),
        withTiming(1, { duration: 900, easing: Easing.inOut(Easing.sin) }),
      ),
      -1,
    );
    return () => {
      ring.value = 1;
    };
  }, [ring]);
  const ringStyle = useAnimatedStyle(() => ({ transform: [{ scale: ring.value }] }));

  const decline = async () => {
    haptic.medium();
    try {
      await api.endCall(String(sessionId));
    } catch {
      // ignore
    }
    router.replace('/(tabs)');
  };

  const accept = () => {
    haptic.heavy();
    setAccepting(true);
    router.replace({
      pathname: `/call/${String(sessionId)}`,
      params: {
        channelName: String(channelName ?? ''),
        agoraToken: String(agoraToken ?? ''),
        therapistName: String(callerName ?? ''),
        therapistId: '',
      },
    });
  };

  return (
    <LinearGradient
      colors={['#0A2A26', '#04130F']}
      style={[styles.fill, { paddingTop: insets.top + 60, paddingBottom: insets.bottom + 48 }]}
    >
      <Text style={[styles.microLabel, { textAlign: 'center', letterSpacing: 2 }]}>INCOMING CALL</Text>
      <View style={styles.avatarHost}>
        <Animated.View style={[styles.ring, ringStyle]}>
          <View style={styles.ringInner} />
        </Animated.View>
        <View style={styles.avatarWrap}>
          <Avatar firstName={(callerName ?? 'U').slice(0, 1)} lastName="" size={104} />
        </View>
      </View>
      <Text style={[styles.name, { textAlign: 'center', marginTop: 26 }]}>{callerName ?? 'A member'}</Text>
      <Text style={[styles.sub, { textAlign: 'center', marginTop: 6 }]}>Seeking a session with you</Text>

      <View style={styles.controls}>
        <PressableScale haptic="heavy" pressScale={0.9} onPress={decline} style={[styles.circleBtn, { backgroundColor: '#E53935' }]}>
          <PhoneOff size={26} color="#FFFFFF" strokeWidth={2.1} />
        </PressableScale>
        <PressableScale
          haptic="heavy"
          pressScale={0.9}
          onPress={accept}
          disabled={accepting}
          style={[styles.circleBtn, { backgroundColor: '#16A34A', width: 76, height: 76 }]}
        >
          <Phone size={28} color="#FFFFFF" strokeWidth={2.1} />
        </PressableScale>
      </View>
      <View style={styles.labels}>
        <Text style={[styles.label, { width: 68, textAlign: 'center' }]}>Decline</Text>
        <Text style={[styles.label, { width: 68, textAlign: 'center' }]}>Accept</Text>
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  microLabel: { color: '#8FD9CF', fontSize: 11, fontWeight: '700' },
  avatarHost: { alignItems: 'center', justifyContent: 'center', marginTop: 60 },
  ring: {
    position: 'absolute',
    width: 150,
    height: 150,
    borderRadius: 75,
    backgroundColor: 'rgba(45, 212, 191, 0.18)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  ringInner: { width: 128, height: 128, borderRadius: 64, backgroundColor: 'rgba(45,212,191,0.12)' },
  avatarWrap: {
    overflow: 'hidden',
    borderWidth: 3,
    borderColor: 'rgba(45,212,191,0.5)',
    borderRadius: 52,
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 56,
    marginTop: 'auto',
  },
  circleBtn: {
    width: 68,
    height: 68,
    borderRadius: 34,
    alignItems: 'center',
    justifyContent: 'center',
  },
  labels: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 78,
    marginTop: 14,
  },
  label: { color: '#8FD9CF', fontSize: 13, fontWeight: '600' },
  name: { color: '#FFFFFF', fontSize: 26, fontWeight: '800' },
  sub: { color: '#8FD9CF', fontSize: 15, fontWeight: '500' },
});
