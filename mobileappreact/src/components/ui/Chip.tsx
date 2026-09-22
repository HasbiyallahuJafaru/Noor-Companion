import React from 'react';
import { View, Text, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import Animated, { Layout, ZoomIn, ZoomOut } from 'react-native-reanimated';
import { Check } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { PressableScale } from './PressableScale';
import { haptic } from '../../lib/haptics';
import { enterPop, enterList } from '../../theme/motion';

interface ChipProps {
  label: string;
  selected?: boolean;
  onPress?: () => void;
  color?: 'teal' | 'gold' | 'neutral';
  style?: StyleProp<ViewStyle>;
}

export function Chip({ label, selected = false, onPress, color = 'teal', style }: ChipProps) {
  const { palette, type, radius } = useTheme();
  const accent = color === 'gold' ? palette.gold : color === 'neutral' ? palette.textSecondary : palette.teal;
  const accentSoft = color === 'gold' ? palette.goldSoft : color === 'neutral' ? palette.backgroundElevated : palette.tealSoft;

  return (
    <PressableScale
      haptic="light"
      onPress={onPress}
      style={[
        styles.chip,
        {
          borderRadius: radius.pill,
          backgroundColor: selected ? accentSoft : 'transparent',
          borderColor: selected ? accent : palette.border,
          borderWidth: 1.2,
        },
        style,
      ]}
    >
      <Text
        style={[
          type.bodySmall(selected ? accent : palette.textSecondary),
          { fontWeight: selected ? '700' : '500' },
        ]}
      >
        {label}
      </Text>
    </PressableScale>
  );
}

interface SelectableCardProps {
  title: string;
  subtitle?: string;
  selected: boolean;
  onPress: () => void;
  index?: number;
  style?: StyleProp<ViewStyle>;
}

/** Onboarding selection card with a spring check badge. */
export function SelectableCard({ title, subtitle, selected, onPress, index, style }: SelectableCardProps) {
  const { palette, type, radius, shadows } = useTheme();
  return (
    <Animated.View entering={index !== undefined ? enterList(index) : undefined}>
    <PressableScale
      haptic="medium"
      onPress={onPress}
      style={[
        styles.card,
        {
          borderRadius: radius.lg,
          backgroundColor: selected ? palette.tealTint : palette.surface,
          borderColor: selected ? palette.teal : palette.border,
        },
        selected && shadows.tealGlow,
        style,
      ]}
    >
      <View style={styles.row}>
        <View style={styles.textWrap}>
          <Text style={type.headingSmall(palette.text)}>{title}</Text>
          {subtitle ? (
            <Text style={[type.bodySmall(palette.textSecondary), styles.subtitle]}>{subtitle}</Text>
          ) : null}
        </View>
        {selected && (
          <Animated.View
            entering={enterPop()}
            exiting={ZoomOut.duration(120)}
            layout={Layout.springify()}
            style={[styles.check, { backgroundColor: palette.teal, borderRadius: 999 }]}
          >
            <Check size={14} color="#FFFFFF" strokeWidth={3} />
          </Animated.View>
        )}
      </View>
    </PressableScale>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    justifyContent: 'center',
  },
  card: {
    borderWidth: 1.5,
    paddingHorizontal: 18,
    paddingVertical: 16,
  },
  row: { flexDirection: 'row', alignItems: 'center' },
  textWrap: { flex: 1 },
  subtitle: { marginTop: 3 },
  check: { width: 26, height: 26, alignItems: 'center', justifyContent: 'center' },
});
