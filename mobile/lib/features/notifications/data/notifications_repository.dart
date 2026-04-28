/// notifications_repository.dart — API calls for the notifications feature.
///
/// Fetches the user's notification feed and marks all as read.
library;

import 'package:dio/dio.dart';
import '../domain/notification_model.dart';

/// Data access layer for notification-related API calls.
class NotificationsRepository {
  const NotificationsRepository(this._dio);

  final Dio _dio;

  /// Fetches the authenticated user's notifications newest-first.
  ///
  /// [page] starts at 1. [limit] defaults to 20 (max 50 enforced by backend).
  /// Returns notifications and the current unread count for the badge.
  ///
  /// Throws [DioException] on network or server errors.
  Future<NotificationsResponse> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    return NotificationsResponse.fromJson(res.data!);
  }

  /// Marks all unread notifications as read.
  /// Throws [DioException] on failure.
  Future<void> markAllRead() async {
    await _dio.post<void>('/notifications/read-all');
  }
}
