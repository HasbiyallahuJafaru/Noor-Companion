/// Domain models for the admin feature.
/// Mirrors the shapes returned by /api/v1/admin/* endpoints.
library;

// ── Analytics ─────────────────────────────────────────────────────────────────

/// Platform-wide summary statistics shown on the admin dashboard.
class AdminAnalytics {
  const AdminAnalytics({
    required this.totalUsers,
    required this.activeToday,
    required this.paidSubscribers,
    required this.totalTherapists,
    required this.pendingTherapists,
    required this.callSessionsThisMonth,
  });

  final int totalUsers;
  final int activeToday;
  final int paidSubscribers;
  final int totalTherapists;
  final int pendingTherapists;
  final int callSessionsThisMonth;

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalUsers: json['totalUsers'] as int,
      activeToday: json['activeToday'] as int,
      paidSubscribers: json['paidSubscribers'] as int,
      totalTherapists: json['totalTherapists'] as int,
      pendingTherapists: json['pendingTherapists'] as int,
      callSessionsThisMonth: json['callSessionsThisMonth'] as int,
    );
  }
}

// ── Users ─────────────────────────────────────────────────────────────────────

/// A user record as returned in admin user list responses.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.subscriptionTier,
    required this.isActive,
    required this.createdAt,
    this.currentStreak,
    this.lastEngagedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String subscriptionTier;
  final bool isActive;
  final DateTime createdAt;
  final int? currentStreak;
  final DateTime? lastEngagedAt;

  String get fullName => '$firstName $lastName';
  bool get isPaid => subscriptionTier == 'paid';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>?;
    return AdminUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      subscriptionTier: json['subscriptionTier'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentStreak: streak?['currentStreak'] as int?,
      lastEngagedAt: streak?['lastEngagedAt'] != null
          ? DateTime.parse(streak!['lastEngagedAt'] as String)
          : null,
    );
  }
}

/// Full admin user detail, including streak data.
class AdminUserDetail extends AdminUser {
  const AdminUserDetail({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.role,
    required super.subscriptionTier,
    required super.isActive,
    required super.createdAt,
    super.currentStreak,
    super.lastEngagedAt,
    required this.supabaseId,
    this.longestStreak,
    this.totalDays,
  });

  final String supabaseId;
  final int? longestStreak;
  final int? totalDays;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>?;
    return AdminUserDetail(
      id: json['id'] as String,
      supabaseId: json['supabaseId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      subscriptionTier: json['subscriptionTier'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentStreak: streak?['currentStreak'] as int?,
      longestStreak: streak?['longestStreak'] as int?,
      totalDays: streak?['totalDays'] as int?,
      lastEngagedAt: streak?['lastEngagedAt'] != null
          ? DateTime.parse(streak!['lastEngagedAt'] as String)
          : null,
    );
  }
}

// ── Therapists ────────────────────────────────────────────────────────────────

/// A therapist profile as returned in the pending-approval list.
class PendingTherapist {
  const PendingTherapist({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.specialisations,
    required this.qualifications,
    required this.yearsExperience,
    required this.sessionRateNgn,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String bio;
  final List<String> specialisations;
  final List<String> qualifications;
  final int yearsExperience;
  final int sessionRateNgn;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  factory PendingTherapist.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PendingTherapist(
      id: json['id'] as String,
      userId: json['userId'] as String,
      firstName: user['firstName'] as String? ?? '',
      lastName: user['lastName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      specialisations: List<String>.from(json['specialisations'] as List? ?? []),
      qualifications: List<String>.from(json['qualifications'] as List? ?? []),
      yearsExperience: json['yearsExperience'] as int? ?? 0,
      sessionRateNgn: json['sessionRateNgn'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

/// A content item as returned in the admin content list.
class AdminContentItem {
  const AdminContentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.tags,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  factory AdminContentItem.fromJson(Map<String, dynamic> json) {
    return AdminContentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isActive: json['isActive'] as bool,
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AdminContentItem copyWith({bool? isActive}) {
    return AdminContentItem(
      id: id,
      title: title,
      category: category,
      tags: tags,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────

/// Generic pagination metadata attached to list responses.
class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
  });

  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
    );
  }
}
