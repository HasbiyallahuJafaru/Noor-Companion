import React, { useState } from 'react';
import { View, Text, StyleSheet, FlatList, Switch } from 'react-native';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { ChevronLeft, Plus, Sparkles, BookOpen, HandHeart } from 'lucide-react-native';
import { useTheme } from '../../../src/theme';
import { api } from '../../../src/lib/api';
import { Card, Badge, Chip, Skeleton, EmptyState, ErrorState, PressableScale } from '../../../src/components';
import { relativeTime } from '../../../src/lib/format';
import { enterList } from '../../../src/theme/motion';
import Animated from 'react-native-reanimated';
import { haptic } from '../../../src/lib/haptics';
import type { AdminContentItem } from '../../../src/lib/types';

const AURORA = require('../../../src/components/core/AppBackground').AppBackground;

const CATEGORIES = ['', 'dhikr', 'duas', 'recitations'];

export default function AdminContent() {
  const { palette, type, radius } = useTheme();
  const insets = useSafeAreaInsets();
  const qc = useQueryClient();
  const [category, setCategory] = useState('');
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ['admin-content', category],
    queryFn: () => api.adminContent({ category: category || undefined }),
  });

  const items = data?.items ?? [];

  const toggle = async (item: AdminContentItem) => {
    haptic.light();
    try {
      await api.adminToggleContent(item.id, !item.isActive);
      qc.invalidateQueries({ queryKey: ['admin-content'] });
    } catch {
      // surfaced by refetch
    }
  };

  const iconFor = (cat: string) =>
    cat === 'dhikr' ? Sparkles : cat === 'duas' ? HandHeart : BookOpen;

  return (
    <View style={[styles.fill, { backgroundColor: palette.background, paddingTop: insets.top }]}>
      <AURORA />
      <View style={styles.header}>
        <PressableScale haptic="light" pressScale={0.9} onPress={() => router.back()} style={[styles.back, { backgroundColor: palette.surface, borderColor: palette.border }]}>
          <ChevronLeft size={22} color={palette.text} strokeWidth={2.2} />
        </PressableScale>
        <Text style={type.headingMedium(palette.text)}>Content</Text>
        <PressableScale haptic="medium" pressScale={0.9} onPress={() => router.push('/admin/content/add')} style={[styles.add, { backgroundColor: palette.teal }]}>
          <Plus size={20} color="#FFFFFF" strokeWidth={2.4} />
        </PressableScale>
      </View>

      <View style={styles.chips}>
        {CATEGORIES.map((c) => (
          <Chip key={c} label={c === '' ? 'All' : c.charAt(0).toUpperCase() + c.slice(1)} selected={category === c} onPress={() => setCategory(c)} />
        ))}
      </View>

      {isLoading ? (
        <View style={styles.skeletons}>
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} height={80} radius={radius.lg} />
          ))}
        </View>
      ) : isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : items.length === 0 ? (
        <EmptyState title="No content found" body="Add your first item with the + button." />
      ) : (
        <FlatList
          data={items}
          keyExtractor={(i) => i.id}
          contentContainerStyle={{ padding: 20, gap: 12 }}
          renderItem={({ item, index }) => {
            const Icon = iconFor(item.category);
            return (
              <Animated.View entering={enterList(index)}>
                <Card padding={16}>
                  <View style={styles.row}>
                    <View style={[styles.icon, { backgroundColor: palette.tealSoft, borderRadius: radius.sm }]}>
                      <Icon size={18} color={palette.teal} strokeWidth={1.9} />
                    </View>
                    <View style={{ flex: 1, marginLeft: 12 }}>
                      <Text style={type.headingSmall(palette.text)} numberOfLines={1}>
                        {item.title}
                      </Text>
                      <View style={[styles.metaRow, { marginTop: 5 }]}>
                        <Badge label={item.category} color="teal" />
                        <Text style={type.micro(palette.textMuted)}>{relativeTime(item.createdAt)}</Text>
                      </View>
                    </View>
                    <Switch
                      value={item.isActive}
                      onValueChange={() => toggle(item)}
                      trackColor={{ true: palette.teal, false: palette.borderStrong }}
                      thumbColor="#FFFFFF"
                    />
                  </View>
                </Card>
              </Animated.View>
            );
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 14,
  },
  back: {
    width: 42,
    height: 42,
    borderRadius: 21,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  add: { width: 42, height: 42, borderRadius: 21, alignItems: 'center', justifyContent: 'center' },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, paddingHorizontal: 20 },
  skeletons: { padding: 20, gap: 12 },
  row: { flexDirection: 'row', alignItems: 'center' },
  icon: { width: 38, height: 38, alignItems: 'center', justifyContent: 'center' },
  metaRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
