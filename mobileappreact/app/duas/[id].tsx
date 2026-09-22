import React from 'react';
import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Bookmark, BookMarked, BookOpen } from 'lucide-react-native';
import { useTheme } from '../../src/theme';
import { useDuas, useRecordProgress } from '../../src/lib/queries';
import { useUiStore } from '../../src/lib/ui-store';
import { Screen, ArabicBlock, AudioBar, Button, Chip, Skeleton, ErrorState, PressableScale } from '../../src/components';
import { haptic } from '../../src/lib/haptics';

export default function DuaDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { palette, type, radius } = useTheme();
  const { data, isLoading, isError, refetch } = useDuas();
  const item = data?.find((d) => d.id === id);
  const record = useRecordProgress();
  const bookmarks = useUiStore((s) => s.bookmarks);
  const hydrated = useUiStore((s) => s.hydrated);
  const toggleBookmark = useUiStore((s) => s.toggleBookmark);
  const [read, setRead] = React.useState(false);

  if (isLoading) {
    return (
      <Screen back title="Dua">
        <View style={{ padding: 20 }}>
          <Skeleton height={180} radius={radius.lg} />
        </View>
      </Screen>
    );
  }
  if (isError || !item) {
    return (
      <Screen back title="Dua">
        <ErrorState onRetry={() => refetch()} />
      </Screen>
    );
  }

  const bookmarked = hydrated && bookmarks.includes(item.id);

  return (
    <Screen
      back
      title={item.title}
      bottom={
        <Button
          label={read ? 'Recorded — Barakallahu feek' : 'Mark as Read'}
          onPress={async () => {
            if (read || record.isPending) return;
            setRead(true);
            haptic.success();
            try {
              await record.mutateAsync(item.id);
            } catch {
              // best-effort
            }
          }}
          disabled={read}
          loading={record.isPending}
        />
      }
    >
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <PressableScale
          haptic="light"
          onPress={() => toggleBookmark(item.id)}
          style={[styles.bookmarkBtn, { backgroundColor: palette.surface, borderColor: palette.border }]}
        >
          {bookmarked ? (
            <BookMarked size={20} color={palette.gold} strokeWidth={1.9} />
          ) : (
            <Bookmark size={20} color={palette.textSecondary} strokeWidth={1.9} />
          )}
          <Text style={[type.bodySmall(palette.textSecondary), { marginLeft: 8 }]}>
            {bookmarked ? 'Bookmarked' : 'Bookmark this dua'}
          </Text>
        </PressableScale>

        <ArabicBlock
          animate={false}
          arabic={item.arabicText}
          transliteration={item.transliteration}
          translation={item.translation}
          style={{ marginTop: 16 }}
        />

        {item.audioUrl ? (
          <View style={{ marginTop: 14 }}>
            <AudioBar source={item.audioUrl} label="Recitation" />
          </View>
        ) : null}

        {item.source ? (
          <View style={[styles.sourceRow, { marginTop: 16 }]}>
            <BookOpen size={15} color={palette.textMuted} strokeWidth={1.9} />
            <Text style={[type.bodySmall(palette.textMuted), { marginLeft: 8, fontStyle: 'italic' }]}>
              {item.source}
            </Text>
          </View>
        ) : null}

        {item.tags?.length > 0 && (
          <View style={styles.tagRow}>
            {item.tags.map((t) => (
              <Chip key={t} label={t} color="neutral" />
            ))}
          </View>
        )}
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { padding: 20, paddingBottom: 40 },
  bookmarkBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderRadius: 999,
    borderWidth: 1,
  },
  sourceRow: { flexDirection: 'row', alignItems: 'center' },
  tagRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 14 },
});
