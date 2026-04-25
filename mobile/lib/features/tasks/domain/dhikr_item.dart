/// Domain model for a single dhikr phrase used in the counter widget.
/// Contains the Arabic text, transliteration, translation, and target count.
library;

class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.targetCount,
    this.audioUrl,
  });

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;

  /// Number of repetitions required to complete this dhikr.
  final int targetCount;

  /// Optional CDN URL for audio recitation. Null until Phase 2.
  final String? audioUrl;
}

/// The standard tasbih set — 33 + 33 + 34 repetitions.
const kTasbihSet = [
  DhikrItem(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ اللهِ',
    transliteration: 'Subḥāna llāh',
    translation: 'Glory be to Allah',
    targetCount: 33,
  ),
  DhikrItem(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Al-ḥamdu lillāh',
    translation: 'All praise is due to Allah',
    targetCount: 33,
  ),
  DhikrItem(
    id: 'allahuakbar',
    arabic: 'اللهُ أَكْبَرُ',
    transliteration: 'Allāhu Akbar',
    translation: 'Allah is the Greatest',
    targetCount: 34,
  ),
];
