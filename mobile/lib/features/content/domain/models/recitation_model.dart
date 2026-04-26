/// API-backed model for a Quran surah with verses and audio.
/// Returned by GET /api/v1/content/recitations (list) and
/// GET /api/v1/islamic/quran/:surahNumber (full detail with verses).
library;

import 'verse_model.dart';

class RecitationModel {
  const RecitationModel({
    required this.id,
    required this.surahNumber,
    required this.nameArabic,
    required this.nameEnglish,
    required this.verseCount,
    required this.revelationType,
    this.audioUrl,
    this.verses,
  });

  final String id;

  /// Surah number 1–114.
  final int surahNumber;

  final String nameArabic;
  final String nameEnglish;
  final int verseCount;

  /// "Meccan" or "Medinan".
  final String revelationType;

  /// Alafasy full-surah audio URL. Null in list view; populated in detail view.
  final String? audioUrl;

  /// Individual verses. Null in list view; populated when fetching detail.
  final List<VerseModel>? verses;

  factory RecitationModel.fromJson(Map<String, dynamic> json) =>
      RecitationModel(
        id: json['id'] as String? ?? json['surahNumber'].toString(),
        surahNumber: (json['surahNumber'] as num).toInt(),
        nameArabic: json['nameArabic'] as String,
        nameEnglish: json['nameEnglish'] as String,
        verseCount: (json['verseCount'] as num).toInt(),
        revelationType: json['revelationType'] as String? ?? '',
        audioUrl: json['audioUrl'] as String?,
        verses: (json['verses'] as List?)
            ?.map((v) => VerseModel.fromJson(v as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'nameArabic': nameArabic,
        'nameEnglish': nameEnglish,
        'verseCount': verseCount,
        'revelationType': revelationType,
        'audioUrl': audioUrl,
      };
}
