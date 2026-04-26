/// API-backed model for a dua from the content library.
/// Returned by GET /api/v1/content/duas.
library;

class DuaModel {
  const DuaModel({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.occasion,
    required this.tags,
    this.audioUrl,
    this.source,
  });

  final String id;

  /// Short English title, e.g. "Dua before eating".
  final String title;

  final String arabicText;
  final String transliteration;
  final String translation;

  /// Occasion category — e.g. "morning", "eating", "anxiety".
  final String occasion;

  final List<String> tags;

  /// Supabase Storage CDN URL. Null when no audio has been uploaded.
  final String? audioUrl;

  /// Hadith or Quran source reference, e.g. "Bukhari 7/88".
  final String? source;

  factory DuaModel.fromJson(Map<String, dynamic> json) => DuaModel(
        id: json['id'] as String,
        title: json['title'] as String,
        arabicText: json['arabicText'] as String,
        transliteration: json['transliteration'] as String,
        translation: json['translation'] as String,
        occasion: json['occasion'] as String? ?? 'general',
        tags: List<String>.from((json['tags'] as List?) ?? []),
        audioUrl: json['audioUrl'] as String?,
        source: json['source'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabicText': arabicText,
        'transliteration': transliteration,
        'translation': translation,
        'occasion': occasion,
        'tags': tags,
        'audioUrl': audioUrl,
        'source': source,
      };
}
