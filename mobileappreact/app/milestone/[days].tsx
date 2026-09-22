import React, { useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, { ZoomIn } from 'react-native-reanimated';
import { useTheme } from '../../src/theme';
import { Screen, ArabicBlock, Button, Confetti } from '../../src/components';
import { MILESTONES } from '../../src/lib/types';

export default function MilestoneScreen() {
  const { days } = useLocalSearchParams<{ days: string }>();
  const dayCount = parseInt(String(days), 10) || 7;
  const { palette, type, radius } = useTheme();
  const milestone = MILESTONES.find((m) => m.days === dayCount) ?? MILESTONES[0];

  useEffect(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
  }, []);

  return (
    <Screen close onClose={() => router.replace('/(tabs)')} chrome>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false} bounces={false}>
        <Confetti />
        <Animated.View entering={ZoomIn.springify().damping(12)} style={styles.badge}>
          <LinearGradient colors={[palette.gold, palette.goldDeep]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={{ borderRadius: radius.xl * 2 }}>
            <View style={[styles.badgeInner, { borderColor: 'rgba(255,255,255,0.35)' }]}>
              <Text style={type.arabic(44, '#FFFFFF')}>{milestone.arabicName}</Text>
            </View>
          </LinearGradient>
        </Animated.View>
        <Text style={[type.heading(palette.text), styles.title]}>{milestone.englishName}</Text>
        <Text style={[type.headingSmall(palette.gold), { marginTop: 4 }]}>{milestone.days} days of clarity</Text>
        <ArabicBlock
          index={1}
          arabic={milestone.arabicAyah}
          transliteration={milestone.transliteration}
          translation={milestone.translation}
          reference={milestone.reference}
          style={{ marginTop: 28 }}
        />
        <Text style={[type.body(palette.textSecondary), styles.closing]}>
          This milestone belongs to every quiet battle you chose not to lose. Carry it gently.
        </Text>
        <View style={{ marginTop: 30 }}>
          <Button label="Continue" onPress={() => router.replace('/(tabs)')} />
        </View>
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { flexGrow: 1, padding: 24, justifyContent: 'center', paddingBottom: 60 },
  badge: { alignSelf: 'center', marginTop: 10 },
  badgeInner: {
    width: 140,
    height: 140,
    borderRadius: 70,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: { textAlign: 'center', marginTop: 22 },
  closing: { textAlign: 'center', marginTop: 20 },
});
