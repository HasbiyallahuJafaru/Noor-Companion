/// App user model — mirrors the backend User record returned from GET /api/v1/users/me.
/// Supabase Auth owns email and password; this model holds app-specific fields only.
library;

class UserModel {
  const UserModel({
    required this.id,
    required this.supabaseId,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.subscriptionTier,
    this.avatarUrl,
    this.streak,
  });

  final String id;
  final String supabaseId;
  final String firstName;
  final String lastName;

  /// 'user' | 'therapist' | 'admin'
  final String role;

  /// 'free' | 'paid'
  final String subscriptionTier;

  final String? avatarUrl;
  final UserStreak? streak;

  bool get isPaid => subscriptionTier == 'paid';
  bool get isAdmin => role == 'admin';
  bool get isTherapist => role == 'therapist';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      supabaseId: json['supabaseId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      subscriptionTier: json['subscriptionTier'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      streak: json['streak'] != null
          ? UserStreak.fromJson(json['streak'] as Map<String, dynamic>)
          : null,
    );
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? subscriptionTier,
    UserStreak? streak,
  }) {
    return UserModel(
      id: id,
      supabaseId: supabaseId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streak: streak ?? this.streak,
    );
  }
}

/// Streak data nested inside the user profile response.
class UserStreak {
  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    this.lastEngagedAt,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final DateTime? lastEngagedAt;

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      totalDays: json['totalDays'] as int,
      lastEngagedAt: json['lastEngagedAt'] != null
          ? DateTime.parse(json['lastEngagedAt'] as String)
          : null,
    );
  }
}
