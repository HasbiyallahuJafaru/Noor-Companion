import React, { useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import * as Haptics from 'expo-haptics';
import { useTheme } from '../../src/theme';
import { ArabicBlock, Button, Confetti } from '../../src/components';
import { InterventionShell } from '../../src/components/shared/InterventionShell';

const AYAH = {
  arabic: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا',
  transliteration: 'Wallazeena jaahadoo feenaa lanahdiyannahum subulanaa',
  translation: 'But those who strive for Us, We will surely guide them to Our ways.',
  reference: 'Surah Al-Ankabut 29:69',
};

/** Step 4: gentle affirmation + celebration, then home or a therapist. */
export default function InterventionAffirm() {
  const { palette, type } = useTheme();

  useEffect(() => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
  }, []);

  return (
    <InterventionShell step={4}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false} bounces={false}>
        <Confetti />
        <View style={styles.hero}>
          <Text style={type.heading(palette.text)}>You're doing well.</Text>
          <Text style={[type.body(palette.textSecondary), { marginTop: 6 }]}>That took strength.</Text>
        </View>
        <ArabicBlock
          index={1}
          arabic={AYAH.arabic}
          transliteration={AYAH.transliteration}
          translation={AYAH.translation}
          reference={AYAH.reference}
          style={{ marginTop: 30 }}
        />
        <View style={styles.ctaStack}>
          <Button label="Return Home" onPress={() => router.replace('/(tabs)')} />
          <Button
            label="Call a Therapist"
            variant="outline"
            onPress={() => {
              router.replace('/(tabs)');
              setTimeout(() => router.push('/(tabs)/therapists'), 350);
            }}
          />
        </View>
      </ScrollView>
    </InterventionShell>
  );
}

const styles = StyleSheet.create({
  scroll: { flexGrow: 1, padding: 24, justifyContent: 'center', paddingBottom: 60 },
  hero: { alignItems: 'center', marginTop: 30 },
  ctaStack: { gap: 12, marginTop: 30 },
});
