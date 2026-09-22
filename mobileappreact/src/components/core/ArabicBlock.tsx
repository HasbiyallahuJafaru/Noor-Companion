import React from 'react';
import { View, Text, StyleSheet, StyleProp, ViewStyle } from 'react-native';
import { Sparkles } from 'lucide-react-native';
import { useTheme } from '../../theme';
import { GlassCard } from '../ui/GlassCard';

interface ArabicBlockProps {
  arabic: string;
  transliteration?: string;
  translation?: string;
  reference?: string;
  arabicSize?: number;
  style?: StyleProp<ViewStyle>;
  animate?: boolean;
  index?: number;
}

/**
 * Sacred text in three voices: Amiri for the Arabic, an italic serif for the
 * transliteration, and the interface sans for the translation, so the reading
 * aid never reads as body copy. Screen readers read the translation.
 */
export function ArabicBlock({
  arabic,
  transliteration,
  translation,
  reference,
  arabicSize = 26,
  style,
  animate = true,
  index = 0,
}: ArabicBlockProps) {
  const { palette, type, radius } = useTheme();
  return (
    <GlassCard
      index={index}
      animate={animate}
      padding={20}
      style={[{ backgroundColor: palette.tealTint, borderWidth: 1, borderColor: palette.border }, style]}
    >
      <View accessibilityRole="text" accessibilityLabel={translation}>
        <Text style={[type.arabic(arabicSize, palette.text), styles.arabic]}>{arabic}</Text>
        {(transliteration || translation) && (
          <View style={styles.dividerRow}>
            <View style={[styles.dividerLine, { backgroundColor: palette.hairline }]} />
            <Sparkles size={13} color={palette.teal} strokeWidth={2} />
            <View style={[styles.dividerLine, { backgroundColor: palette.hairline }]} />
          </View>
        )}
        {transliteration ? (
          <Text style={[type.quote(13.5, palette.textSecondary), styles.transliteration]}>
            {transliteration}
          </Text>
        ) : null}
        {translation ? (
          <Text style={[type.body(palette.textBody), styles.translation]}>{translation}</Text>
        ) : null}
        {reference ? (
          <Text style={[type.caption(palette.teal), styles.reference]}>{reference}</Text>
        ) : null}
      </View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  arabic: { textAlign: 'right', writingDirection: 'rtl' as const },
  dividerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginVertical: 14,
  },
  dividerLine: { flex: 1, height: 1 },
  transliteration: { textAlign: 'left' },
  translation: { marginTop: 6, textAlign: 'left' },
  reference: { marginTop: 10, letterSpacing: 0.6 },
});
