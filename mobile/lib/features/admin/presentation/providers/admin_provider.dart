/// Riverpod providers for the admin feature.
/// Each provider is scoped to one domain area: analytics, users, therapists, content.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

// ── Analytics ──────────────────────────────────────────────────────────────────

/// Fetches dashboard analytics once and caches the result.
/// Invalidate with ref.invalidate(adminAnalyticsProvider) to refresh.
final adminAnalyticsProvider =
    AsyncNotifierProvider<AdminAnalyticsNotifier, AdminAnalytics>(
  AdminAnalyticsNotifier.new,
);

class AdminAnalyticsNotifier extends AsyncNotifier<AdminAnalytics> {
  @override
  Future<AdminAnalytics> build() {
    return ref.read(adminRepositoryProvider).fetchAnalytics();
  }

  /// Reloads the analytics snapshot from the server.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).fetchAnalytics(),
    );
  }
}

// ── Users ──────────────────────────────────────────────────────────────────────

const _sentinel = Object();

/// State for the admin user list, including filter params.
class AdminUsersState {
  const AdminUsersState({
    this.users = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
    this.search,
    this.roleFilter,
    this.tierFilter,
  });

  final List<AdminUser> users;
  final PaginationMeta? pagination;
  final bool isLoading;
  final String? error;
  final String? search;
  final String? roleFilter;
  final String? tierFilter;

  AdminUsersState copyWith({
    List<AdminUser>? users,
    PaginationMeta? pagination,
    bool? isLoading,
    Object? error = _sentinel,
    Object? search = _sentinel,
    Object? roleFilter = _sentinel,
    Object? tierFilter = _sentinel,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      search: search == _sentinel ? this.search : search as String?,
      roleFilter:
          roleFilter == _sentinel ? this.roleFilter : roleFilter as String?,
      tierFilter:
          tierFilter == _sentinel ? this.tierFilter : tierFilter as String?,
    );
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(
  AdminUsersNotifier.new,
);

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() {
    Future.microtask(load);
    return const AdminUsersState(isLoading: true);
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  /// Loads users using current filter state.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.fetchUsers(
        role: state.roleFilter,
        subscriptionTier: state.tierFilter,
        search: state.search,
      );
      state = state.copyWith(
        users: result.users,
        pagination: result.pagination,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Failed to load users.'),
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(search: query.isEmpty ? null : query);
    await load();
  }

  Future<void> setRoleFilter(String? role) async {
    state = state.copyWith(roleFilter: role);
    await load();
  }

  Future<void> setTierFilter(String? tier) async {
    state = state.copyWith(tierFilter: tier);
    await load();
  }

  /// Suspends or restores a user and updates the local list.
  Future<String?> toggleUserActive(
    String userId, {
    required bool isActive,
  }) async {
    try {
      await _repo.updateUser(userId, isActive: isActive);
      state = state.copyWith(
        users: state.users.map((u) {
          if (u.id != userId) return u;
          return AdminUser.fromJson({
            'id': u.id,
            'firstName': u.firstName,
            'lastName': u.lastName,
            'role': u.role,
            'subscriptionTier': u.subscriptionTier,
            'isActive': isActive,
            'createdAt': u.createdAt.toIso8601String(),
          });
        }).toList(),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e, 'Update failed.');
    }
  }
}

/// Single-user detail — auto-disposes when the detail screen is popped.
final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUserDetail, String>((ref, userId) {
  return ref.read(adminRepositoryProvider).fetchUserById(userId);
});

// ── Therapists ─────────────────────────────────────────────────────────────────

class AdminTherapistsState {
  const AdminTherapistsState({
    this.pending = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PendingTherapist> pending;
  final bool isLoading;
  final String? error;

  AdminTherapistsState copyWith({
    List<PendingTherapist>? pending,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return AdminTherapistsState(
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

final adminTherapistsProvider =
    NotifierProvider<AdminTherapistsNotifier, AdminTherapistsState>(
  AdminTherapistsNotifier.new,
);

class AdminTherapistsNotifier extends Notifier<AdminTherapistsState> {
  @override
  AdminTherapistsState build() {
    Future.microtask(load);
    return const AdminTherapistsState(isLoading: true);
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pending = await _repo.fetchPendingTherapists();
      state = state.copyWith(pending: pending, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Failed to load therapists.'),
      );
    }
  }

  /// Approves and removes the therapist from the pending list.
  Future<String?> approve(String therapistProfileId) async {
    try {
      await _repo.approveTherapist(therapistProfileId);
      state = state.copyWith(
        pending:
            state.pending.where((t) => t.id != therapistProfileId).toList(),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e, 'Approval failed.');
    }
  }

  /// Rejects and removes the therapist from the pending list.
  Future<String?> reject(String therapistProfileId, String reason) async {
    try {
      await _repo.rejectTherapist(therapistProfileId, reason);
      state = state.copyWith(
        pending:
            state.pending.where((t) => t.id != therapistProfileId).toList(),
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e, 'Rejection failed.');
    }
  }
}

// ── Content ────────────────────────────────────────────────────────────────────

class AdminContentState {
  const AdminContentState({
    this.items = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
    this.categoryFilter,
  });

  final List<AdminContentItem> items;
  final PaginationMeta? pagination;
  final bool isLoading;
  final String? error;
  final String? categoryFilter;

  AdminContentState copyWith({
    List<AdminContentItem>? items,
    PaginationMeta? pagination,
    bool? isLoading,
    Object? error = _sentinel,
    Object? categoryFilter = _sentinel,
  }) {
    return AdminContentState(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      categoryFilter: categoryFilter == _sentinel
          ? this.categoryFilter
          : categoryFilter as String?,
    );
  }
}

final adminContentProvider =
    NotifierProvider<AdminContentNotifier, AdminContentState>(
  AdminContentNotifier.new,
);

class AdminContentNotifier extends Notifier<AdminContentState> {
  @override
  AdminContentState build() {
    Future.microtask(load);
    return const AdminContentState(isLoading: true);
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result =
          await _repo.fetchAllContent(category: state.categoryFilter);
      state = state.copyWith(
        items: result.items,
        pagination: result.pagination,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Failed to load content.'),
      );
    }
  }

  Future<void> setCategoryFilter(String? category) async {
    state = state.copyWith(categoryFilter: category);
    await load();
  }

  /// Optimistically flips isActive and patches the server.
  Future<String?> toggleActive(String contentId, {required bool isActive}) async {
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == contentId ? i.copyWith(isActive: isActive) : i)
          .toList(),
    );
    try {
      await _repo.toggleContentActive(contentId, isActive: isActive);
      return null;
    } on DioException catch (e) {
      // Revert on failure.
      state = state.copyWith(
        items: state.items
            .map(
                (i) => i.id == contentId ? i.copyWith(isActive: !isActive) : i)
            .toList(),
      );
      return _extractError(e, 'Update failed.');
    }
  }

  /// Creates an item server-side and prepends it locally.
  Future<String?> addContent({
    required String title,
    required String arabicText,
    required String transliteration,
    required String translation,
    required String category,
    required List<String> tags,
    String? audioUrl,
  }) async {
    try {
      final item = await _repo.createContent(
        title: title,
        arabicText: arabicText,
        transliteration: transliteration,
        translation: translation,
        category: category,
        tags: tags,
        audioUrl: audioUrl,
      );
      state = state.copyWith(items: [item, ...state.items]);
      return null;
    } on DioException catch (e) {
      return _extractError(e, 'Failed to create content.');
    }
  }
}

// ── Broadcast ──────────────────────────────────────────────────────────────────

sealed class BroadcastState {
  const BroadcastState();
}

class BroadcastIdle extends BroadcastState {
  const BroadcastIdle();
}

class BroadcastSending extends BroadcastState {
  const BroadcastSending();
}

class BroadcastSuccess extends BroadcastState {
  const BroadcastSuccess(this.sent);
  final int sent;
}

class BroadcastError extends BroadcastState {
  const BroadcastError(this.message);
  final String message;
}

final broadcastProvider =
    NotifierProvider<BroadcastNotifier, BroadcastState>(
  BroadcastNotifier.new,
);

class BroadcastNotifier extends Notifier<BroadcastState> {
  @override
  BroadcastState build() => const BroadcastIdle();

  Future<void> send({
    required String title,
    required String body,
    required String targetRole,
  }) async {
    state = const BroadcastSending();
    try {
      final sent = await ref.read(adminRepositoryProvider).broadcast(
            title: title,
            body: body,
            targetRole: targetRole,
          );
      state = BroadcastSuccess(sent);
    } on DioException catch (e) {
      state = BroadcastError(_extractError(e, 'Broadcast failed.'));
    }
  }

  void reset() => state = const BroadcastIdle();
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _extractError(DioException e, String fallback) {
  try {
    final msg = e.response?.data?['error']?['message'];
    return (msg is String) ? msg : fallback;
  } catch (_) {
    return fallback;
  }
}
