import React from 'react';
import { View, Text, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import * as Haptics from 'expo-haptics';
import { Star } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { PressableScale } from '../ui/PressableScale';
import { initials } from '../../lib/format';
import { LinearGradient } from 'expo-linear-gradient';

/** Initials avatar with a soft brand gradient fallback. */
export function Avatar({
  url,
  firstName,
  lastName,
  size = 48,
}: {
  url?: string | null;
  firstName: string;
  lastName: string;
  size?: number;
}) {
  const { palette } = useTheme();
  if (url) {
    return (
      <View
        style={{
          width: size,
          height: size,
          borderRadius: size / 2,
          overflow: 'hidden',
          backgroundColor: palette.tealSoft,
        }}
      >
        <ExpoImage uri={url} size={size} />
      </View>
    );
  }
  return (
    <LinearGradient
      colors={[palette.teal, palette.tealDeep]}
      style={{
        width: size,
        height: size,
        borderRadius: size / 2,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Text
        style={{
          fontFamily: undefined,
          fontWeight: '800',
          fontSize: size * 0.36,
          color: '#FFFFFF',
          letterSpacing: 0.5,
        }}
      >
        {initials(firstName, lastName)}
      </Text>
    </LinearGradient>
  );
}

function ExpoImage({ uri, size }: { uri: string; size: number }) {
  const Image = require('expo-image').Image;
  return <Image source={{ uri }} style={{ width: size, height: size }} contentFit="cover" />;
}

/** Five-star rating row; interactive when onRate is provided. */
export function StarRating({
  value,
  size = 36,
  onRate,
  interactive = false,
}: {
  value: number;
  size?: number;
  onRate?: (v: number) => void;
  interactive?: boolean;
}) {
  const { palette } = useTheme();
  return (
    <View style={styles.row}>
      {[1, 2, 3, 4, 5].map((i) => {
        const star = (
          <Star
            size={size}
            color={i <= value ? palette.gold : palette.borderStrong}
            fill={i <= value ? palette.gold : 'transparent'}
            strokeWidth={1.75}
          />
        );
        if (!interactive) return <View key={i}>{star}</View>;
        return (
          <PressableScale
            key={i}
            haptic="medium"
            pressScale={0.85}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
              onRate?.(i);
            }}
            style={{ padding: 4 }}
          >
            {star}
          </PressableScale>
        );
      })}
    </View>
  );
}

/** Small status pill. */
export function Badge({
  label,
  color = 'teal',
  style,
}: {
  label: string;
  color?: 'teal' | 'gold' | 'danger' | 'success' | 'purple' | 'muted';
  style?: StyleProp<ViewStyle>;
}) {
  const { palette, type } = useTheme();
  const map = {
    teal: [palette.tealSoft, palette.teal],
    gold: [palette.goldSoft, palette.goldDeep],
    danger: [palette.dangerSoft, palette.danger],
    success: [palette.successSoft, palette.success],
    purple: [palette.purpleSoft, palette.purple],
    muted: [palette.backgroundElevated, palette.textSecondary],
  } as const;
  const [bg, fg] = map[color];
  return (
    <View style={[styles.badge, { backgroundColor: bg }, style]}>
      <Text style={[type.micro(fg), { textTransform: 'uppercase', letterSpacing: 0.5 }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: 8 },
  badge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
  },
});
