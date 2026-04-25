/// Milestone definitions — unlocked at 7, 30, 90, 180, and 365 days clean.
/// Each carries an Arabic virtue name, English name, and an ayah of encouragement.
library;

class Milestone {
  const Milestone({
    required this.days,
    required this.arabicName,
    required this.englishName,
    required this.arabicAyah,
    required this.transliteration,
    required this.translation,
    required this.reference,
  });

  /// Days-clean threshold that unlocks this badge.
  final int days;

  /// Arabic virtue name displayed large on the badge.
  final String arabicName;

  final String englishName;
  final String arabicAyah;
  final String transliteration;
  final String translation;

  /// Surah:Ayah reference string, e.g. "2:153".
  final String reference;
}

/// All five milestones in ascending order.
const kMilestones = [
  Milestone(
    days: 7,
    arabicName: 'صَبْر',
    englishName: 'Sabr — Patience',
    arabicAyah:
        'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
    transliteration:
        'Yā ayyuhā lladhīna āmanū staʿīnū biṣ-ṣabri waṣ-ṣalāh',
    translation:
        'O you who believe, seek help through patience and prayer.',
    reference: '2:153',
  ),
  Milestone(
    days: 30,
    arabicName: 'تَوْبَة',
    englishName: 'Tawbah — Repentance',
    arabicAyah:
        'إِنَّ اللَّهَ يُحِبُّ التَّوَّابِينَ وَيُحِبُّ الْمُتَطَهِّرِينَ',
    transliteration:
        'Inna llāha yuḥibbu t-tawwābīna wa yuḥibbu l-mutaṭahhirīn',
    translation:
        'Indeed, Allah loves those who repent and those who purify themselves.',
    reference: '2:222',
  ),
  Milestone(
    days: 90,
    arabicName: 'إِسْتِقَامَة',
    englishName: 'Istiqamah — Steadfastness',
    arabicAyah:
        'إِنَّ الَّذِينَ قَالُوا رَبُّنَا اللَّهُ ثُمَّ اسْتَقَامُوا',
    transliteration:
        'Inna lladhīna qālū rabbunā llāhu thumma staqāmū',
    translation:
        'Indeed, those who say "Our Lord is Allah" and then remain steadfast.',
    reference: '41:30',
  ),
  Milestone(
    days: 180,
    arabicName: 'تَوَكُّل',
    englishName: 'Tawakkul — Trust in Allah',
    arabicAyah:
        'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    transliteration: 'Wa man yatawakkal ʿalā llāhi fa huwa ḥasbuh',
    translation: 'And whoever relies upon Allah — then He is sufficient for him.',
    reference: '65:3',
  ),
  Milestone(
    days: 365,
    arabicName: 'يَقِين',
    englishName: 'Yaqeen — Certainty',
    arabicAyah:
        'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ',
    transliteration:
        'Alā inna awliyāʾa llāhi lā khawfun ʿalayhim wa lā hum yaḥzanūn',
    translation:
        'Unquestionably, the allies of Allah — there will be no fear concerning them, '
        'nor will they grieve.',
    reference: '10:62',
  ),
];

/// Returns the [Milestone] for [days], or null if [days] is not a milestone.
Milestone? milestoneForDays(int days) {
  for (final m in kMilestones) {
    if (m.days == days) return m;
  }
  return null;
}

/// Returns all milestones unlocked at or below [currentDays].
List<Milestone> unlockedMilestones(int currentDays) =>
    kMilestones.where((m) => currentDays >= m.days).toList();
