import React, { useEffect } from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Play, Pause } from 'lucide-react-native';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { PressableScale } from '../ui/PressableScale';
import { formatDuration } from '../../lib/format';

interface AudioBarProps {
  source: string;
  /** Optional label like reciter or surah name. */
  label?: string;
}

/** Compact audio player with a breathing play button and linear progress. */
export function AudioBar({ source, label }: AudioBarProps) {
  const { palette, type, radius } = useTheme();
  const player = useAudioPlayer({ uri: source });
  const status = useAudioPlayerStatus(player);
  const breathe = useSharedValue(1);

  useEffect(() => {
    if (status.playing) {
      breathe.value = withRepeat(
        withTiming(1.06, { duration: 1200, easing: Easing.inOut(Easing.sin) }),
        -1,
        true,
      );
    } else {
      breathe.value = withTiming(1);
    }
  }, [status.playing, breathe]);

  const buttonStyle = useAnimatedStyle(() => ({ transform: [{ scale: breathe.value }] }));

  const progress = status.duration > 0 ? status.currentTime / status.duration : 0;

  return (
    <View
      style={[
        styles.bar,
        {
          backgroundColor: palette.tealTint,
          borderRadius: radius.md,
          borderColor: palette.border,
        },
      ]}
    >
      <PressableScale
        haptic="medium"
        pressScale={0.9}
        onPress={() => {
          if (status.playing) player.pause();
          else player.play();
        }}
        style={[styles.playBtn, { backgroundColor: palette.teal, borderRadius: 999 }]}
      >
        <Animated.View style={buttonStyle}>
          {status.playing ? (
            <Pause size={18} color="#FFFFFF" fill="#FFFFFF" strokeWidth={0} />
          ) : (
            <Play size={18} color="#FFFFFF" fill="#FFFFFF" strokeWidth={0} style={{ marginLeft: 2 }} />
          )}
        </Animated.View>
      </PressableScale>
      <View style={styles.trackWrap}>
        {label ? <Text style={type.caption(palette.textSecondary)} numberOfLines={1}>{label}</Text> : null}
        <View style={[styles.track, { backgroundColor: palette.hairline }]}>
          <View style={[styles.fill, { backgroundColor: palette.teal, width: `${Math.round(progress * 100)}%` }]} />
        </View>
        <Text style={type.micro(palette.textMuted)}>
          {formatDuration(Math.floor(status.currentTime))}
          {status.duration > 0 ? ` / ${formatDuration(Math.floor(status.duration))}` : ''}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    padding: 14,
    borderWidth: 1,
  },
  playBtn: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  trackWrap: { flex: 1, gap: 6 },
  track: { height: 4, borderRadius: 2, overflow: 'hidden' },
  fill: { height: '100%', borderRadius: 2 },
});
