import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, FlatList, TextInput, RefreshControl } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router, useFocusEffect } from 'expo-router';
import { Search, Star } from 'lucide-react-native';
import { useQueryClient } from '@tanstack/react-query';
import { useTheme } from '../../src/theme';
import { useTherapists } from '../../src/lib/queries';
import { GlassCard, Chip, Skeleton, EmptyState, ErrorState, PressableScale, Avatar } from '../../src/components';
import { enterList } from '../../src/theme/motion';
import Animated from 'react-native-reanimated';
import { formatNgnShort } from '../../src/lib/format';
import type { TherapistModel } from '../../src/lib/types';

const AURORA = require('../../src/components/core/AuroraBackground').AuroraBackground;

export default function TherapistDirectory() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const [query, setQuery] = useState('');
  const [specialisation, setSpecialisation] = useState<string | undefined>();
  const [language, setLanguage] = useState<string | undefined>();
  const { data, isLoading, isError, refetch, isRefetching } = useTherapists({
    specialisation,
    language,
  });
  const qc = useQueryClient();

  useFocusEffect(
    React.useCallback(() => {
      qc.invalidateQueries({ queryKey: ['therapists'] });
    }, [qc]),
  );

  const all = data?.therapists ?? [];
  const filtered = useMemo(() => {
    if (!query.trim()) return all;
    const q = query.trim().toLowerCase();
    return all.filter(
      (t) =>
        `${t.firstName} ${t.lastName}`.toLowerCase().includes(q) ||
        t.specialisations.some((s) => s.toLowerCase().includes(q)),
    );
  }, [all, query]);

  const specs = useMemo(
    () => Array.from(new Set(all.flatMap((t) => t.specialisations))).slice(0, 6),
    [all],
  );
  const langs = useMemo(
    () => Array.from(new Set(all.flatMap((t) => t.languagesSpoken))).slice(0, 5),
    [all],
  );

  return (
    <View style={[styles.fill, { backgroundColor: palette.background }]}>
      <AURORA />
      <FlatList
        data={filtered}
        keyExtractor={(t) => t.id}
        contentContainerStyle={{ paddingTop: insets.top + 18, paddingBottom: 130, gap: 12 }}
        refreshControl={
          <RefreshControl refreshing={isRefetching} onRefresh={() => refetch()} tintColor={palette.teal} />
        }
        ListHeaderComponent={
          <View style={{ marginBottom: 8 }}>
            <Text style={[type.heading(palette.text), styles.title]}>Therapists</Text>
            <Text style={[type.body(palette.textSecondary), { paddingHorizontal: 20, marginTop: 2 }]}>
              Connect with someone who understands.
            </Text>
            <View
              style={[
                styles.search,
                { backgroundColor: palette.surface, borderColor: palette.border, borderRadius: radius.md },
              ]}
            >
              <Search size={18} color={palette.textMuted} strokeWidth={2} />
              <TextInput
                placeholder="Search by name"
                placeholderTextColor={palette.textMuted}
                value={query}
                onChangeText={setQuery}
                autoCapitalize="none"
                style={[type.body(palette.text), styles.searchInput]}
              />
            </View>
            {specs.length > 0 && (
              <View style={[styles.chips, { paddingHorizontal: 20 }]}>
                {specs.map((s) => (
                  <Chip
                    key={s}
                    label={s}
                    selected={specialisation === s}
                    onPress={() => setSpecialisation(specialisation === s ? undefined : s)}
                  />
                ))}
              </View>
            )}
            {langs.length > 0 && (
              <View style={[styles.chips, { paddingHorizontal: 20 }]}>
                {langs.map((l) => (
                  <Chip
                    key={l}
                    label={l}
                    color="gold"
                    selected={language === l}
                    onPress={() => setLanguage(language === l ? undefined : l)}
                  />
                ))}
              </View>
            )}
          </View>
        }
        ListEmptyComponent={
          isLoading ? (
            <View style={styles.skeletons}>
              <Skeleton height={120} radius={radius.lg} />
              <Skeleton height={120} radius={radius.lg} />
              <Skeleton height={120} radius={radius.lg} />
            </View>
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : (
            <EmptyState title="No therapists found" body="Try clearing filters." />
          )
        }
        renderItem={({ item, index }) => (
          <Animated.View entering={enterList(index)} style={{ paddingHorizontal: 20 }}>
            <TherapistCard therapist={item} onPress={() => router.push(`/therapists/${item.id}`)} />
          </Animated.View>
        )}
      />
    </View>
  );
}

function TherapistCard({ therapist: t, onPress }: { therapist: TherapistModel; onPress: () => void }) {
  const { palette, type, radius } = useTheme();
  return (
    <PressableScale haptic="medium" onPress={onPress}>
      <GlassCard padding={18}>
        <View style={styles.cardRow}>
          <Avatar url={t.avatarUrl} firstName={t.firstName} lastName={t.lastName} size={54} />
          <View style={{ flex: 1, marginLeft: 14 }}>
            <View style={styles.nameRow}>
              <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                {t.firstName} {t.lastName}
              </Text>
              {typeof t.averageRating === 'number' && t.averageRating > 0 && (
                <View style={styles.rating}>
                  <Star size={13} color={palette.gold} fill={palette.gold} strokeWidth={0} />
                  <Text style={[type.micro(palette.goldDeep), { marginLeft: 3, fontSize: 11 }]}>
                    {t.averageRating.toFixed(1)}
                  </Text>
                </View>
              )}
            </View>
            <Text style={[type.bodySmall(palette.textSecondary), { marginTop: 3 }]} numberOfLines={1}>
              {t.specialisations.slice(0, 2).join(' · ')}
            </Text>
            <Text style={[type.caption(palette.textMuted), { marginTop: 6 }]}>
              {t.yearsExperience} yrs · {formatNgnShort(t.sessionRateNgn)}/session
            </Text>
          </View>
        </View>
      </GlassCard>
    </PressableScale>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  title: { paddingHorizontal: 20 },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
    height: 48,
    borderWidth: 1,
    marginHorizontal: 20,
    marginTop: 14,
  },
  searchInput: { flex: 1, paddingVertical: 0 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  skeletons: { paddingHorizontal: 20, gap: 12 },
  cardRow: { flexDirection: 'row', alignItems: 'center' },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rating: { flexDirection: 'row', alignItems: 'center' },
});
