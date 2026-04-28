/// Admin repository — all API calls for admin-only endpoints.
/// Consumed by admin Riverpod providers. Never called directly from widgets.
library;

import 'package:dio/dio.dart';
import '../domain/admin_models.dart';

/// Provides typed access to all /api/v1/admin/* endpoints.
class AdminRepository {
  const AdminRepository(this._dio);

  final Dio _dio;

  // ── Analytics ───────────────────────────────────────────────────────────────

  /// Fetches platform summary statistics for the admin dashboard.
  Future<AdminAnalytics> fetchAnalytics() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/analytics');
    return AdminAnalytics.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  // ── Users ───────────────────────────────────────────────────────────────────

  /// Returns a paginated user list, optionally filtered.
  ///
  /// [page] starts at 1. [limit] defaults to 20.
  Future<({List<AdminUser> users, PaginationMeta pagination})> fetchUsers({
    String? role,
    String? subscriptionTier,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {
        // ignore: use_null_aware_elements
        if (role != null) 'role': role,
        // ignore: use_null_aware_elements
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    return (
      users: (data['users'] as List)
          .map((j) => AdminUser.fromJson(j as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(
        data['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  /// Returns the full profile for a single user.
  Future<AdminUserDetail> fetchUserById(String userId) async {
    final res =
        await _dio.get<Map<String, dynamic>>('/admin/users/$userId');
    return AdminUserDetail.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Updates a user's [isActive] status or [subscriptionTier].
  Future<void> updateUser(
    String userId, {
    bool? isActive,
    String? subscriptionTier,
  }) async {
    await _dio.patch<void>(
      '/admin/users/$userId',
      data: {
        'isActive': ?isActive,
        'subscriptionTier': ?subscriptionTier,
      },
    );
  }

  // ── Therapists ──────────────────────────────────────────────────────────────

  /// Returns therapist profiles awaiting admin approval.
  Future<List<PendingTherapist>> fetchPendingTherapists() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/admin/therapists/pending');
    final list = res.data!['data'] as List;
    return list
        .map((j) => PendingTherapist.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Approves a therapist profile.
  Future<void> approveTherapist(String therapistProfileId) async {
    await _dio.post<void>('/admin/therapists/$therapistProfileId/approve');
  }

  /// Rejects a therapist profile with a mandatory reason.
  Future<void> rejectTherapist(
    String therapistProfileId,
    String reason,
  ) async {
    await _dio.post<void>(
      '/admin/therapists/$therapistProfileId/reject',
      data: {'reason': reason},
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────────

  /// Returns all content items (active + inactive), optionally filtered.
  Future<({List<AdminContentItem> items, PaginationMeta pagination})>
      fetchAllContent({
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/content',
      queryParameters: {
        'category': ?category,
        'page': page,
        'limit': limit,
      },
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    return (
      items: (data['items'] as List)
          .map((j) => AdminContentItem.fromJson(j as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(
        data['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  /// Creates a new content item.
  Future<AdminContentItem> createContent({
    required String title,
    required String arabicText,
    required String transliteration,
    required String translation,
    required String category,
    required List<String> tags,
    String? audioUrl,
    int sortOrder = 0,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/content',
      data: {
        'title': title,
        'arabicText': arabicText,
        'transliteration': transliteration,
        'translation': translation,
        'category': category,
        'tags': tags,
        'audioUrl': ?audioUrl,
        'sortOrder': sortOrder,
      },
    );
    return AdminContentItem.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Toggles a content item's [isActive] field.
  Future<void> toggleContentActive(String contentId, {required bool isActive}) async {
    await _dio.patch<void>(
      '/admin/content/$contentId',
      data: {'isActive': isActive},
    );
  }

  // ── Broadcast ───────────────────────────────────────────────────────────────

  /// Sends a broadcast push notification to all users of [targetRole].
  /// Returns the number of tokens targeted.
  Future<int> broadcast({
    required String title,
    required String body,
    required String targetRole,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/admin/notifications/broadcast',
      data: {'title': title, 'body': body, 'targetRole': targetRole},
    );
    return (res.data!['data'] as Map<String, dynamic>)['sent'] as int? ?? 0;
  }
}
