/// Domain model for a therapist directory entry.
/// Matches the shape returned by GET /api/v1/therapists and GET /api/v1/therapists/:id.
library;

class TherapistModel {
  const TherapistModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.specialisations,
    required this.qualifications,
    required this.languagesSpoken,
    required this.yearsExperience,
    required this.sessionRateNgn,
    required this.totalSessions,
    this.averageRating,
    this.availabilityJson,
    this.avatarUrl,
  });

  /// TherapistProfile ID — used for navigation and call initiation.
  final String id;
  final String firstName;
  final String lastName;
  final String bio;

  /// e.g. ['anxiety', 'grief', 'spiritual wellness']
  final List<String> specialisations;

  /// e.g. ['MSc Psychology', 'BACP Accredited']
  final List<String> qualifications;

  final List<String> languagesSpoken;
  final int yearsExperience;

  /// Session rate in Nigerian Naira — display only.
  final int sessionRateNgn;

  final int totalSessions;

  /// Null when no sessions have been rated yet.
  final double? averageRating;

  /// Weekly availability schedule from the backend. Null until therapist sets it.
  final Map<String, dynamic>? availabilityJson;

  final String? avatarUrl;

  String get fullName => '$firstName $lastName';

  /// The top two specialisations shown on cards and detail header.
  List<String> get topSpecialisations =>
      specialisations.length > 2 ? specialisations.sublist(0, 2) : specialisations;

  factory TherapistModel.fromJson(Map<String, dynamic> json) {
    return TherapistModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      bio: json['bio'] as String,
      specialisations: List<String>.from(json['specialisations'] as List),
      qualifications: List<String>.from(json['qualifications'] as List),
      languagesSpoken: List<String>.from(json['languagesSpoken'] as List),
      yearsExperience: (json['yearsExperience'] as num).toInt(),
      sessionRateNgn: (json['sessionRateNgn'] as num).toInt(),
      totalSessions: (json['totalSessions'] as num).toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      availabilityJson: json['availabilityJson'] as Map<String, dynamic>?,
    );
  }
}
