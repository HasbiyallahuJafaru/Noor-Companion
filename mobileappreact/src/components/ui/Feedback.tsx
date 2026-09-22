import React, { useEffect } from 'react';
import { View, Text, StyleSheet, StyleProp, ViewStyle, DimensionValue } from 'react-native';
import { RefreshCw, AlertCircle, Inbox } from 'lucide-react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withSequence,
  withTiming,
  interpolate,
} from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { Button } from './Button';
import { easing, duration } from '../../theme/motion';

/** Shimmer skeleton block matching the final layout's shape. */
export function Skeleton({
  width = '100%',
  height = 16,
  radius = 10,
  style,
}: {
  width?: DimensionValue;
  height?: number;
  radius?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const { palette } = useTheme();
  const t = useSharedValue(0);
  useEffect(() => {
    t.value = withRepeat(
      withSequence(
        withTiming(1, { duration: 1100, easing: easing.inOut }),
        withTiming(0, { duration: 1100, easing: easing.inOut }),
      ),
      -1,
    );
  }, [t]);
  const styleAnim = useAnimatedStyle(() => ({
    opacity: interpolate(t.value, [0, 1], [0.5, 1]),
  }));
  return (
    <Animated.View
      style={[
        { width, height, borderRadius: radius, backgroundColor: palette.isDark ? '#1D2145' : '#E7E6F0' },
        styleAnim,
        style,
      ]}
    />
  );
}

export function EmptyState({
  icon,
  title,
  body,
  actionLabel,
  onAction,
}: {
  icon?: React.ReactNode;
  title: string;
  body?: string;
  actionLabel?: string;
  onAction?: () => void;
}) {
  const { palette, type } = useTheme();
  return (
    <View style={styles.center}>
      <View style={[styles.iconWrap, { backgroundColor: palette.tealTint }]}>
        {icon ?? <Inbox size={26} color={palette.teal} strokeWidth={1.75} />}
      </View>
      <Text style={[type.headingSmall(palette.text), styles.title]}>{title}</Text>
      {body ? (
        <Text style={[type.bodySmall(palette.textSecondary), styles.body, { maxWidth: 280 }]}>{body}</Text>
      ) : null}
      {actionLabel && onAction && (
        <View style={{ marginTop: 20, alignSelf: 'center' }}>
          <Button label={actionLabel} onPress={onAction} size="md" style={{ alignSelf: 'center' }} />
        </View>
      )}
    </View>
  );
}

export function ErrorState({ message, onRetry }: { message?: string; onRetry?: () => void }) {
  const { palette, type } = useTheme();
  return (
    <View style={styles.center}>
      <View style={[styles.iconWrap, { backgroundColor: palette.dangerSoft }]}>
        <AlertCircle size={26} color={palette.danger} strokeWidth={1.75} />
      </View>
      <Text style={[type.headingSmall(palette.text), styles.title]}>Something went wrong</Text>
      <Text style={[type.bodySmall(palette.textSecondary), styles.body, { maxWidth: 280 }]}>
        {message ?? 'Please check your connection and try again.'}
      </Text>
      {onRetry && (
        <View style={{ marginTop: 20, alignSelf: 'center' }}>
          <Button label="Try Again" onPress={onRetry} variant="outline" size="md" icon={<RefreshCw size={16} color={palette.teal} strokeWidth={2} />} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  iconWrap: { width: 64, height: 64, borderRadius: 32, alignItems: 'center', justifyContent: 'center', marginBottom: 16 },
  title: { textAlign: 'center' },
  body: { textAlign: 'center', marginTop: 6 },
});
