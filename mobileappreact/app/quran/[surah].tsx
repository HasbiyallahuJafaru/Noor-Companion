import React from 'react';
import { View, Text, StyleSheet, FlatList } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useSurah } from '../../src/lib/queries';
import { Screen, AudioBar, Skeleton, ErrorState, Badge } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';

export default function SurahScreen() {
  const { surah } = useLocalSearchParams<{ surah: string }>();
  const surahNumber = parseInt(String(surah), 10) || 1;
  const { palette, type, radius } = useTheme();
  const { data, isLoading, isError, refetch } = useSurah(surahNumber);

  return (
    <Screen
      back
      title={data?.nameEnglish ?? 'Surah'}
      subtitle={data ? `${data.verseCount} verses · ${data.revelationType}` : undefined}
    >
      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1, 2, 3, 4].map((i) => (
            <Skeleton key={i} height={90} radius={radius.lg} />
          ))}
        </View>
      ) : isError || !data ? (
        <ErrorState onRetry={() => refetch()} />
      ) : (
        <FlatList
          data={data.verses ?? []}
          keyExtractor={(v) => String(v.number)}
          contentContainerStyle={styles.list}
          ListHeaderComponent={
            <View style={{ gap: 14, paddingHorizontal: 20 }}>
              {surahNumber !== 1 && surahNumber !== 9 && (
                <View style={[styles.bismillah, { backgroundColor: palette.tealTint, borderRadius: radius.lg }]}>
                  <Text style={type.arabic(22, palette.tealDeep, false)}>بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</Text>
                </View>
              )}
              {data.audioUrl ? <AudioBar source={data.audioUrl} label="Surah recitation" /> : null}
            </View>
          }
          renderItem={({ item, index }) => (
            <Animated.View entering={enterList(Math.min(index, 8))} style={{ paddingHorizontal: 20 }}>
              <View
                style={[
                  styles.verse,
                  {
                    backgroundColor: palette.surface,
                    borderColor: palette.border,
                    borderRadius: radius.lg,
                  },
                ]}
              >
                <View style={styles.verseHeader}>
                  <View style={[styles.verseNum, { backgroundColor: palette.tealSoft }]}>
                    <Text style={[type.micro(palette.tealDeep), { fontSize: 10 }]}>{item.number}</Text>
                  </View>
                  <View style={{ flex: 1 }} />
                </View>
                <Text style={[type.arabic(21, palette.text, false), styles.arabic]}>{item.arabicText}</Text>
                <Text style={[type.bodySmall(palette.textSecondary), styles.translation]}>{item.translation}</Text>
              </View>
            </Animated.View>
          )}
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  skeletons: { padding: 20, gap: 10 },
  list: { paddingTop: 14, paddingBottom: 40, gap: 12 },
  bismillah: { alignItems: 'center', paddingVertical: 18 },
  verse: { borderWidth: 1, padding: 18 },
  verseHeader: { flexDirection: 'row', alignItems: 'center' },
  verseNum: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  arabic: { marginTop: 12, textAlign: 'right', writingDirection: 'rtl' as const },
  translation: { marginTop: 10 },
});
