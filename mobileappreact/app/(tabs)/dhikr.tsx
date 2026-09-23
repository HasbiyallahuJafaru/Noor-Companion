import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, FlatList, Pressable } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { useTheme } from '../../src/theme';
import { useDhikr } from '../../src/lib/queries';
import { GlassCard, Chip, Skeleton, EmptyState, ErrorState, PressableScale } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';

const TAGS = ['all', 'morning', 'evening', 'general', 'forgiveness'];

export default function DhikrLibrary() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const [tag, setTag] = useState('all');
  const { data, isLoading, isError, refetch } = useDhikr(tag);

  const items = useMemo(() => data ?? [], [data]);

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <FlatList
        data={items}
        keyExtractor={(d) => d.id}
        numColumns={2}
        columnWrapperStyle={{ gap: 12, paddingHorizontal: 20 }}
        contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: insets.bottom + 130, gap: 12 }}
        ListHeaderComponent={
          <View style={{ marginBottom: 14 }}>
            <Text style={[type.heading(palette.text), styles.title]}>Dhikr</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.chips}
            >
              {TAGS.map((t) => (
                <Chip
                  key={t}
                  label={t.charAt(0).toUpperCase() + t.slice(1)}
                  selected={tag === t}
                  onPress={() => setTag(t)}
                />
              ))}
            </ScrollView>
          </View>
        }
        ListEmptyComponent={
          isLoading ? (
            <View style={styles.skeletons}>
              {[0, 1, 2, 3].map((i) => (
                <Skeleton key={i} width={'47%'} height={170} radius={radius.lg} />
              ))}
            </View>
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : (
            <EmptyState title="No dhikr here yet" body="Try a different filter." />
          )
        }
        renderItem={({ item, index }) => (
          <Animated.View entering={enterList(index % 8)} style={{ flex: 1 }}>
            <PressableScale haptic="medium" onPress={() => router.push(`/dhikr/${item.id}`)} style={{ flex: 1 }}>
              <GlassCard padding={16} style={{ height: 170, justifyContent: 'space-between' }}>
                <Text style={[type.arabic(16, palette.text), styles.arabic]} numberOfLines={3}>
                  {item.arabicText}
                </Text>
                <View>
                  <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                    {item.title}
                  </Text>
                  <Text style={[type.caption(palette.textMuted), { marginTop: 3 }]}>
                    {item.targetCount}x
                  </Text>
                </View>
              </GlassCard>
            </PressableScale>
          </Animated.View>
        )}
      />
    </View>
  );
}

const AURORA = require('../../src/components/core/AppBackground').AppBackground;

const styles = StyleSheet.create({
  fill: { flex: 1 },
  title: { paddingHorizontal: 20, marginBottom: 14 },
  chips: { paddingHorizontal: 20, gap: 10 },
  skeletons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    paddingHorizontal: 20,
  },
  arabic: { textAlign: 'right', writingDirection: 'rtl' as const },
});
