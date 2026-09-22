import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Droplets } from 'lucide-react-native';
import Animated, { ZoomIn } from 'react-native-reanimated';
import { useTheme } from '../src/theme';
import { Screen, ArabicBlock, Button } from '../src/components';

const AYAH = {
  arabic: 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
  transliteration: "Qul yaa 'ibaadiyal-lazeena asrafoo 'alaaa anfusihim laa taqnatoo mir rahmatillaah",
  translation: 'Say, "O My servants who have transgressed against themselves, do not despair of the mercy of Allah."',
  reference: 'Surah Az-Zumar 39:53',
};

/** Streak-reset mercy screen: Tawbah is always open. */
export default function ReturnScreen() {
  const { palette, type } = useTheme();
  return (
    <Screen chrome>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false} bounces={false}>
        <Animated.View entering={ZoomIn.springify().damping(13)} style={styles.dropWrap}>
          <LinearGradient colors={[palette.teal, palette.tealDeep]} style={styles.drop}>
            <Droplets size={30} color="#FFFFFF" strokeWidth={1.75} />
          </LinearGradient>
        </Animated.View>
        <Text style={[type.heading(palette.text), styles.title]}>Tawbah is always open.</Text>
        <ArabicBlock
          index={1}
          arabic={AYAH.arabic}
          transliteration={AYAH.transliteration}
          translation={AYAH.translation}
          reference={AYAH.reference}
          style={{ marginTop: 26 }}
        />
        <Text style={[type.body(palette.textSecondary), styles.note]}>
          Your counter resets to zero. That's not a punishment — it's a fresh page. What matters is that you came back.
        </Text>
        <View style={{ marginTop: 28 }}>
          <Button label="Start again — بِسْمِ اللَّهِ" onPress={() => router.replace('/(tabs)')} />
        </View>
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { flexGrow: 1, padding: 24, justifyContent: 'center', paddingBottom: 60 },
  dropWrap: { alignSelf: 'center' },
  drop: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderBottomLeftRadius: 12,
    transform: [{ rotate: '45deg' }],
  },
  title: { textAlign: 'center', marginTop: 34 },
  note: { textAlign: 'center', marginTop: 18 },
});
