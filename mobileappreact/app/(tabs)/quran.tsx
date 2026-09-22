import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, FlatList, TextInput } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Search } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { useRecitations } from '../../src/lib/queries';
import { Skeleton, EmptyState, ErrorState, PressableScale } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';

export default function QuranBrowser() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const [query, setQuery] = useState('');
  const { data, isLoading, isError, refetch } = useRecitations();

  const filtered = useMemo(() => {
    const list = data ?? [];
    if (!query.trim()) return list;
    const q = query.trim().toLowerCase();
    return list.filter(
      (s) =>
        s.nameEnglish.toLowerCase().includes(q) ||
        s.nameArabic.includes(query.trim()) ||
        String(s.surahNumber) === q,
    );
  }, [data, query]);

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <FlatList
        data={filtered}
        keyExtractor={(s) => String(s.id ?? s.surahNumber)}
        contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: 130, gap: 8 }}
        ListHeaderComponent={
          <View style={{ marginBottom: 16, paddingHorizontal: 20 }}>
            <Text style={type.heading(palette.text)}>Quran</Text>
            <View
              style={[
                styles.search,
                {
                  backgroundColor: palette.surface,
                  borderColor: palette.border,
                  borderRadius: radius.md,
                  marginTop: 14,
                },
              ]}
            >
              <Search size={18} color={palette.textMuted} strokeWidth={2} />
              <TextInput
                placeholder="Search surah by name or number"
                placeholderTextColor={palette.textMuted}
                value={query}
                onChangeText={setQuery}
                autoCapitalize="none"
                style={[type.body(palette.text), styles.searchInput]}
              />
            </View>
          </View>
        }
        ListEmptyComponent={
          isLoading ? (
            <View style={styles.skeletons}>
              {[0, 1, 2, 3, 4, 5].map((i) => (
                <Skeleton key={i} height={64} radius={radius.md} />
              ))}
            </View>
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : (
            <EmptyState title="No surah found" body="Check the spelling or try a number." />
          )
        }
        renderItem={({ item, index }) => (
          <Animated.View entering={enterList(Math.min(index, 10))} style={{ paddingHorizontal: 20 }}>
            <PressableScale haptic="light" onPress={() => router.push(`/quran/${item.surahNumber}`)}>
              <View
                style={[
                  styles.row,
                  {
                    backgroundColor: palette.surface,
                    borderColor: palette.border,
                    borderRadius: radius.md,
                  },
                ]}
              >
                <View style={[styles.numberCircle, { backgroundColor: palette.tealSoft }]}>
                  <Text style={[type.caption(palette.tealDeep), { fontSize: 11 }]}>{item.surahNumber}</Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={type.headingSmall(palette.text)}>{item.nameEnglish}</Text>
                  <Text style={[type.micro(palette.textMuted), { marginTop: 2 }]}>
                    {item.verseCount} verses · {item.revelationType}
                  </Text>
                </View>
                <Text style={type.arabic(19, palette.text)}>{item.nameArabic}</Text>
              </View>
            </PressableScale>
          </Animated.View>
        )}
      />
    </View>
  );
}

const AURORA = require('../../src/components/core/AuroraBackground').AuroraBackground;

const styles = StyleSheet.create({
  fill: { flex: 1 },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
    height: 48,
    borderWidth: 1,
  },
  searchInput: { flex: 1, paddingVertical: 0 },
  skeletons: { paddingHorizontal: 20, gap: 8 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
  },
  numberCircle: { width: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center' },
});
