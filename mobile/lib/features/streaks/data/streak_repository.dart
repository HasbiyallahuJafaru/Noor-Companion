/// Streak repository — fetches the authenticated user's streak from the backend.
/// Single endpoint: GET /api/v1/streaks/me.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../content/domain/models/streak_model.dart';

class StreakRepository {
  const StreakRepository(this._dio);

  final Dio _dio;

  /// Fetches the current user's streak from the backend.
  /// Returns a zero-state StreakModel when the user has never engaged.
  ///
  /// Throws [DioException] on network failure.
  Future<StreakModel> fetchMyStreak() async {
    final response = await _dio.get('/streaks/me');
    final data = response.data['data'] as Map<String, dynamic>;
    return StreakModel.fromJson(data);
  }
}

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepository(ref.watch(apiClientProvider));
});
