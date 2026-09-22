import React, { useEffect, useRef, useState } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  StyleProp,
  ViewStyle,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { gestureHandlerRootHOC } from 'react-native-gesture-handler';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  runOnJS,
  Easing,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { X } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { spring } from '../../theme/motion';
import { haptic } from '../../lib/haptics';

interface SheetProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  height?: number | 'auto';
  style?: StyleProp<ViewStyle>;
}

/**
 * Draggable bottom sheet: spring presentation, rubber-band drag-to-dismiss,
 * scrim fade. Native-feel without a heavy dependency.
 */
function SheetBase({ visible, onClose, title, children, height = 'auto', style }: SheetProps) {
  const { palette, type, radius } = useTheme();
  const translateY = useSharedValue(600);
  const scrim = useSharedValue(0);
  const drag = useSharedValue(0);
  const [mounted, setMounted] = useState(visible);

  useEffect(() => {
    if (visible) {
      setMounted(true);
      translateY.value = withSpring(0, spring.gentle);
      scrim.value = withTiming(1, { duration: 220, easing: Easing.out(Easing.quad) });
    } else if (mounted) {
      translateY.value = withTiming(600, { duration: 200, easing: Easing.in(Easing.quad) });
      scrim.value = withTiming(0, { duration: 180 });
      const t = setTimeout(() => setMounted(false), 220);
      return () => clearTimeout(t);
    }
  }, [visible, translateY, scrim, mounted]);

  const pan = Gesture.Pan()
    .onUpdate((e) => {
      drag.value = Math.max(0, e.translationY);
    })
    .onEnd((e) => {
      if (e.translationY > 120 || e.velocityY > 900) {
        translateY.value = withSpring(600, spring.gentle);
        scrim.value = withTiming(0, { duration: 180 });
        runOnJS(haptic.medium)();
        runOnJS(onClose)();
      } else {
        drag.value = withSpring(0, spring.snappy);
      }
    });

  const panelStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value + drag.value * 0.9 }],
  }));
  const scrimStyle = useAnimatedStyle(() => ({ opacity: scrim.value }));

  if (!mounted) return null;

  return (
    <Modal transparent visible statusBarTranslucent animationType="none" onRequestClose={onClose}>
      <View style={styles.fill}>
        <StatusBar style={palette.isDark ? 'light' : 'dark'} />
        <Animated.View style={[StyleSheet.absoluteFill, { backgroundColor: palette.scrim }, scrimStyle]}>
          <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
        </Animated.View>
        <GestureDetector gesture={pan}>
          <Animated.View
            style={[
              styles.panel,
              {
                backgroundColor: palette.surface,
                borderTopLeftRadius: radius.xl,
                borderTopRightRadius: radius.xl,
              },
              height !== 'auto' && { height },
              style,
              panelStyle,
            ]}
          >
            <View style={styles.handleWrap}>
              <View style={[styles.handle, { backgroundColor: palette.borderStrong }]} />
            </View>
            {title && (
              <View style={styles.titleRow}>
                <Text style={type.headingMedium(palette.text)}>{title}</Text>
                <Pressable onPress={onClose} hitSlop={12}>
                  <X size={22} color={palette.textMuted} strokeWidth={2} />
                </Pressable>
              </View>
            )}
            <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.body}>
              {children}
            </KeyboardAvoidingView>
          </Animated.View>
        </GestureDetector>
      </View>
    </Modal>
  );
}

export const Sheet = gestureHandlerRootHOC(SheetBase);

const styles = StyleSheet.create({
  fill: { flex: 1, justifyContent: 'flex-end' },
  panel: { paddingBottom: 8 },
  handleWrap: { alignItems: 'center', paddingTop: 10, paddingBottom: 4 },
  handle: { width: 40, height: 5, borderRadius: 3 },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 24,
    paddingTop: 12,
    paddingBottom: 6,
  },
  body: { paddingHorizontal: 24, paddingBottom: 24 },
});
