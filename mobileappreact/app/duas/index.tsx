import React from 'react';
import { View, Text, StyleSheet, FlatList } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Bookmark } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { useDuas } from '../../src/lib/queries';
import { useUiStore } from '../../src/lib/ui-store';
import { GlassCard, Chip, Skeleton, EmptyState, ErrorState, PressableScale, Badge } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';

const OCCASIONS = ['all', 'morning', 'evening', 'eating', 'anxiety', 'travel', 'general'];

export default function DuaLibrary() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const [occasion, setOccasion] = React.useState('all');
  const { data, isLoading, isError, refetch } = useDuas(occasion);
  const bookmarks = useUiStore((s) => s.bookmarks);
  const hydrated = useUiStore((s) => s.hydrated);
  const items = data ?? [];

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <FlatList
        data={items}
        keyExtractor={(d) => d.id}
        contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: 40, gap: 12 }}
        ListHeaderComponent={
          <View style={{ marginBottom: 14 }}>
            <Text style={[type.heading(palette.text), styles.title]}>Duas</Text>
            <View style={styles.chips}>
              {OCCASIONS.map((o) => (
                <Chip
                  key={o}
                  label={o.charAt(0).toUpperCase() + o.slice(1)}
                  selected={occasion === o}
                  onPress={() => setOccasion(o)}
                />
              ))}
            </View>
          </View>
        }
        ListEmptyComponent={
          isLoading || !hydrated ? (
            <View style={styles.skeletons}>
              <Skeleton height={130} radius={radius.lg} />
              <Skeleton height={130} radius={radius.lg} />
              <Skeleton height={130} radius={radius.lg} />
            </View>
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : (
            <EmptyState title="No duas for this occasion" body="Try another filter." />
          )
        }
        renderItem={({ item, index }) => (
          <Animated.View entering={enterList(index)} style={{ paddingHorizontal: 20 }}>
            <PressableScale haptic="medium" onPress={() => router.push(`/duas/${item.id}`)}>
              <GlassCard padding={18}>
                <View style={styles.cardTop}>
                  <View style={{ flex: 1 }}>
                    <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                      {item.title}
                    </Text>
                    <Text style={[type.caption(palette.textMuted), { marginTop: 2, textTransform: 'capitalize' }]}>
                      {item.occasion}
                    </Text>
                  </View>
                  {hydrated && bookmarks.includes(item.id) && (
                    <Bookmark size={18} color={palette.gold} fill={palette.gold} strokeWidth={1.75} />
                  )}
                </View>
                <Text style={[type.arabic(18, palette.text), styles.arabic]} numberOfLines={2}>
                  {item.arabicText}
                </Text>
                <Text style={[type.bodySmall(palette.textSecondary), styles.translation]} numberOfLines={2}>
                  {item.translation}
                </Text>
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
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, paddingHorizontal: 20 },
  skeletons: { paddingHorizontal: 20, gap: 12 },
  cardTop: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  arabic: { marginTop: 12, textAlign: 'right', writingDirection: 'rtl' as const },
  translation: { marginTop: 10 },
});
