/// Domain model for a therapist profile.
/// Specialty determines which section header the card appears under.
/// isAvailable drives the live availability dot and the Call Now button state.
library;

enum TherapistSpecialty { counsellor, islamicScholar }

class TherapistModel {
  const TherapistModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.isAvailable,
    this.avatarUrl,
    this.averageRating,
    this.sessionCount = 0,
  });

  final String id;
  final String name;
  final TherapistSpecialty specialty;

  /// 2–3 sentence bio shown on the detail screen.
  final String bio;

  /// Live availability — green dot when true, grey when false.
  final bool isAvailable;

  /// Remote avatar URL. Null until Phase 4 when real data is wired.
  final String? avatarUrl;

  /// Average session rating out of 5. Null if no sessions yet.
  final double? averageRating;

  final int sessionCount;

  String get specialtyLabel => switch (specialty) {
        TherapistSpecialty.counsellor => 'Licensed Counsellor',
        TherapistSpecialty.islamicScholar => 'Islamic Scholar',
      };
}
