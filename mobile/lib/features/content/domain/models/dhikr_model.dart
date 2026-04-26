/// API-backed model for a dhikr item from the content library.
/// Returned by GET /api/v1/content/dhikr.
library;

class DhikrModel {
  const DhikrModel({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.targetCount,
    required this.tags,
    this.audioUrl,
  });

  final String id;

  /// Short English title, e.g. "Subhanallah".
  final String title;

  /// Arabic text, right-to-left.
  final String arabicText;

  /// Latin phonetic transcription.
  final String transliteration;

  /// English meaning.
  final String translation;

  /// Number of repetitions for a complete tasbih cycle.
  final int targetCount;

  /// Category tags — e.g. ["morning", "general"].
  final List<String> tags;

  /// Supabase Storage CDN URL. Null when no audio has been uploaded.
  final String? audioUrl;

  factory DhikrModel.fromJson(Map<String, dynamic> json) => DhikrModel(
        id: json['id'] as String,
        title: json['title'] as String,
        arabicText: json['arabicText'] as String,
        transliteration: json['transliteration'] as String,
        translation: json['translation'] as String,
        targetCount: (json['targetCount'] as num?)?.toInt() ?? 33,
        tags: List<String>.from((json['tags'] as List?) ?? []),
        audioUrl: json['audioUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabicText': arabicText,
        'transliteration': transliteration,
        'translation': translation,
        'targetCount': targetCount,
        'tags': tags,
        'audioUrl': audioUrl,
      };
}
