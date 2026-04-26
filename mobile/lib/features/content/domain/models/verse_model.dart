/// A single Quran verse (ayah) with Arabic text and translation.
/// Part of a [RecitationModel] surah.
library;

class VerseModel {
  const VerseModel({
    required this.number,
    required this.arabicText,
    required this.translation,
  });

  /// Verse number within the surah (1-based).
  final int number;

  final String arabicText;

  /// English translation (Asad by default).
  final String translation;

  factory VerseModel.fromJson(Map<String, dynamic> json) => VerseModel(
        number: (json['number'] as num).toInt(),
        arabicText: json['arabicText'] as String,
        translation: json['translation'] as String,
      );
}
