/// subscription_repository.dart — API calls for the subscription upgrade flow.
///
/// Handles fetching the signed redirect token from the backend
/// and polling GET /users/me to confirm tier upgrade after payment.
library;

import 'package:dio/dio.dart';
import '../../auth/domain/models/user_model.dart';

/// Data access layer for subscription-related API calls.
class SubscriptionRepository {
  const SubscriptionRepository(this._dio);

  final Dio _dio;

  /// Fetches a short-lived signed redirect URL from the backend.
  ///
  /// The URL encodes the user ID so the Netlify payment page can identify
  /// who is paying without a Supabase session in the browser.
  ///
  /// Returns the full Netlify URL including the signed token query parameter.
  /// Throws [DioException] on network or server errors.
  Future<String> fetchSubscribeRedirectUrl() async {
    final res = await _dio.post<Map<String, dynamic>>('/users/me/subscribe-token');
    final data = res.data!['data'] as Map<String, dynamic>;
    return data['redirectUrl'] as String;
  }

  /// Polls GET /users/me up to [maxAttempts] times with [intervalMs] between each.
  ///
  /// Returns the updated [UserModel] as soon as subscriptionTier == 'paid',
  /// or null if the tier has not updated within the polling window.
  ///
  /// Used after iOS Safari returns to the app to confirm payment was processed.
  Future<UserModel?> pollForPaidTier({
    int maxAttempts = 5,
    int intervalMs = 2000,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (i > 0) {
        await Future<void>.delayed(Duration(milliseconds: intervalMs));
      }

      try {
        final res = await _dio.get<Map<String, dynamic>>('/users/me');
        final user = UserModel.fromJson(
          res.data!['data'] as Map<String, dynamic>,
        );

        if (user.isPaid) return user;
      } on DioException {
        // Network blip — keep polling
      }
    }

    return null;
  }
}
