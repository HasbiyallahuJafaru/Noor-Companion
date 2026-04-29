/// Domain models for the therapist dashboard feature.
/// Covers own-profile data and session history summaries.
library;

// ── Therapist own profile ──────────────────────────────────────────────────────

/// The therapist's own profile as returned by the directory API.
/// Re-uses the same shape as [TherapistModel] but includes approval status.
class TherapistOwnProfile {
  const TherapistOwnProfile({
    required this.id,
    required this.status,
    required this.bio,
    required this.specialisations,
    required this.qualifications,
    required this.languagesSpoken,
    required this.yearsExperience,
    required this.sessionRateNgn,
    required this.totalSessions,
    this.averageRating,
    this.avatarUrl,
  });

  /// TherapistProfile ID.
  final String id;

  /// 'pending' | 'active' | 'rejected'
  final String status;

  final String bio;
  final List<String> specialisations;
  final List<String> qualifications;
  final List<String> languagesSpoken;
  final int yearsExperience;
  final int sessionRateNgn;
  final int totalSessions;
  final double? averageRating;
  final String? avatarUrl;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isRejected => status == 'rejected';

  factory TherapistOwnProfile.fromJson(Map<String, dynamic> json) {
    final ratings = (json['ratings'] as List? ?? [])
        .map((r) => (r['rating'] as num).toDouble())
        .toList();
    final avg = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;

    return TherapistOwnProfile(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      bio: json['bio'] as String? ?? '',
      specialisations: List<String>.from(json['specialisations'] as List? ?? []),
      qualifications: List<String>.from(json['qualifications'] as List? ?? []),
      languagesSpoken: List<String>.from(json['languagesSpoken'] as List? ?? []),
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      sessionRateNgn: (json['sessionRateNgn'] as num?)?.toInt() ?? 0,
      totalSessions: (json['sessions'] as List?)?.length ?? 0,
      averageRating: avg,
      avatarUrl: json['user']?['avatarUrl'] as String?,
    );
  }
}

// ── Session summary ────────────────────────────────────────────────────────────

/// A single call session as shown in the therapist's session history.
class CallSessionSummary {
  const CallSessionSummary({
    required this.id,
    required this.status,
    required this.createdAt,
    this.durationSeconds,
    this.endedAt,
    this.callerFirstName,
    this.callerLastName,
    this.callerAvatarUrl,
    this.rating,
    this.ratingComment,
  });

  final String id;

  /// 'initiated' | 'active' | 'completed' | 'missed' | 'cancelled'
  final String status;

  final DateTime createdAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? callerFirstName;
  final String? callerLastName;
  final String? callerAvatarUrl;
  final int? rating;
  final String? ratingComment;

  String get callerName =>
      [callerFirstName, callerLastName].whereType<String>().join(' ');

  /// Duration formatted as "Xm Ys" or "—" if unavailable.
  String get formattedDuration {
    if (durationSeconds == null || durationSeconds! <= 0) return '—';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  factory CallSessionSummary.fromJson(Map<String, dynamic> json) {
    final ratingJson = json['rating'] as Map<String, dynamic>?;
    final userJson = json['user'] as Map<String, dynamic>?;

    return CallSessionSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      callerFirstName: userJson?['firstName'] as String?,
      callerLastName: userJson?['lastName'] as String?,
      callerAvatarUrl: userJson?['avatarUrl'] as String?,
      rating: (ratingJson?['rating'] as num?)?.toInt(),
      ratingComment: ratingJson?['comment'] as String?,
    );
  }
}

// ── Session history response ───────────────────────────────────────────────────

/// Paginated session history returned by GET /calls/my-sessions.
class SessionHistoryResponse {
  const SessionHistoryResponse({
    required this.sessions,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<CallSessionSummary> sessions;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => sessions.length < total;

  factory SessionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return SessionHistoryResponse(
      sessions: (json['sessions'] as List)
          .map((e) => CallSessionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (pagination['page'] as num).toInt(),
      limit: (pagination['limit'] as num).toInt(),
      total: (pagination['total'] as num).toInt(),
    );
  }
}
