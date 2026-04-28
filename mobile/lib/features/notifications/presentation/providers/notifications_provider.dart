/// notifications_provider.dart — Riverpod state for the notifications feature.
///
/// [NotificationsNotifier] loads and paginates the notification feed.
/// [unreadCountProvider] exposes the badge count for the nav icon.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_model.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

/// Manages the in-app notification feed.
/// Call [load] to fetch from the API and [markAllRead] to clear the badge.
class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    return const NotificationsState();
  }

  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  /// Fetches the first page of notifications from the backend.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final res = await _repo.fetchNotifications();
      state = state.copyWith(
        notifications: res.notifications,
        unreadCount: res.unreadCount,
        isLoading: false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ??
          'Could not load notifications.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong.',
      );
    }
  }

  /// Marks all notifications as read and clears the unread badge.
  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      state = state.copyWith(
        unreadCount: 0,
        notifications: state.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList(),
      );
    } on DioException {
      // Non-critical — badge will self-correct on next load
    }
  }

  /// Called when an in-app FCM message arrives — bumps the badge by 1.
  void incrementUnreadCount() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }
}

// ── Convenience providers ─────────────────────────────────────────────────────

/// Exposes just the unread count for the notification badge.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
