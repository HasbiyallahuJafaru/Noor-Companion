import React, { useEffect } from 'react';
import { View, Text, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { ChevronLeft, X } from 'lucide-react-native';
import Animated, { FadeIn } from 'react-native-reanimated';
import { useTheme } from '../../theme';
import { PressableScale } from './PressableScale';
import { AuroraBackground } from '../core/AuroraBackground';
import { enterScreen } from '../../theme/motion';

interface ScreenProps {
  children: React.ReactNode;
  /** Aurora canvas + safe areas; false for modal/full-bleed screens. */
  chrome?: boolean;
  scroll?: boolean;
  padded?: boolean;
  /** Show a back chevron row (stack screens). */
  back?: boolean;
  /** Show a close X row instead of back. */
  close?: boolean;
  title?: string;
  subtitle?: string;
  right?: React.ReactNode;
  headerRight?: React.ReactNode;
  bottom?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  onBack?: () => void;
  /** Alias for onBack, reads better with close. */
  onClose?: () => void;
  edges?: ('top' | 'bottom' | 'left' | 'right')[];
}

/**
 * Standard screen scaffold: aurora canvas, safe areas, optional header row,
 * optional pinned bottom (panic button / CTA). Content enters with the
 * shared screen-entrance spring.
 */
export function Screen({
  children,
  chrome = true,
  back = false,
  close = false,
  title,
  subtitle,
  right,
  headerRight,
  bottom,
  style,
  onBack,
  onClose,
  edges,
}: ScreenProps) {
  const { palette, type } = useTheme();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const goBack = onBack ?? onClose ?? (() => router.back());

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      {chrome && <AuroraBackground />}
      <View style={[styles.fill, { paddingTop: !edges || edges.includes('top') ? insets.top : 0, paddingBottom: !edges || edges.includes('bottom') ? insets.bottom : 0 }]}>
        <Animated.View entering={enterScreen()} style={styles.fill}>
          {(back || close) && (
            <View style={styles.headerRow}>
              <PressableScale
                haptic="light"
                pressScale={0.9}
                onPress={goBack}
                style={[styles.backBtn, { backgroundColor: palette.surface, borderColor: palette.border }]}
              >
                {close ? (
                  <X size={20} color={palette.text} strokeWidth={2.2} />
                ) : (
                  <ChevronLeft size={22} color={palette.text} strokeWidth={2.2} />
                )}
              </PressableScale>
              {title ? (
                <Text style={[type.headingSmall(palette.text), styles.headerTitle]} numberOfLines={1}>
                  {title}
                </Text>
              ) : (
                <View style={{ flex: 1 }} />
              )}
              <View style={{ minWidth: 42, alignItems: 'flex-end' }}>{headerRight}</View>
            </View>
          )}
          {title && !back && !close && (
            <View style={styles.titleBlock}>
              <Text style={type.heading(palette.text)}>{title}</Text>
              {subtitle ? (
                <Text style={[type.body(palette.textSecondary), styles.subtitle]}>{subtitle}</Text>
              ) : null}
              {right}
            </View>
          )}
          <View style={[styles.fill, styles.content, style]}>{children}</View>
        </Animated.View>
      </View>
      {bottom && (
        <View
          style={[
            styles.bottom,
            {
              paddingBottom: 16,
              paddingHorizontal: 20,
              backgroundColor: palette.isDark ? 'rgba(10,12,26,0.9)' : 'rgba(243,242,249,0.9)',
              borderTopColor: palette.hairline,
            },
          ]}
        >
          {bottom}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  content: {},
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 6,
  },
  backBtn: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  headerTitle: { flex: 1, textAlign: 'center', fontSize: 16 },
  titleBlock: { paddingHorizontal: 20, paddingTop: 12, paddingBottom: 6 },
  subtitle: { marginTop: 4 },
  bottom: {
    paddingTop: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
});
