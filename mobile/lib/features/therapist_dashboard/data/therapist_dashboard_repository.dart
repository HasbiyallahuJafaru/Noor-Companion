/// Repository for the therapist dashboard feature.
/// Covers: own profile fetch, profile update, and session history.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/therapist_dashboard_models.dart';

class TherapistDashboardRepository {
  const TherapistDashboardRepository(this._dio);

  final dynamic _dio;

  /// Fetches the authenticated therapist's own profile.
  /// Uses GET /therapists/me — the backend resolves profile by user ID.
  Future<TherapistOwnProfile> fetchMyProfile() async {
    final response = await _dio.get('/therapists/me');
    final data = response.data['data'] as Map<String, dynamic>;
    return TherapistOwnProfile.fromJson(data);
  }

  /// Creates or updates the authenticated therapist's profile.
  /// Maps to POST /api/v1/therapists/profile.
  ///
  /// @param bio - Professional bio
  /// @param specialisations - List of focus areas
  /// @param qualifications - List of credentials
  /// @param languagesSpoken - Supported languages
  /// @param yearsExperience - Years of practice
  /// @param sessionRateNgn - Session fee in Nigerian Naira
  Future<void> updateProfile({
    required String bio,
    required List<String> specialisations,
    required List<String> qualifications,
    required List<String> languagesSpoken,
    required int yearsExperience,
    required int sessionRateNgn,
  }) async {
    await _dio.post('/therapists/profile', data: {
      'bio': bio,
      'specialisations': specialisations,
      'qualifications': qualifications,
      'languagesSpoken': languagesSpoken,
      'yearsExperience': yearsExperience,
      'sessionRateNgn': sessionRateNgn,
    });
  }

  /// Fetches a page of the therapist's own session history.
  /// Maps to GET /api/v1/calls/my-sessions.
  ///
  /// @param page - 1-indexed page number
  /// @param limit - Items per page (default 20)
  Future<SessionHistoryResponse> fetchSessionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/calls/my-sessions',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return SessionHistoryResponse.fromJson(data);
  }
}

final therapistDashboardRepositoryProvider =
    Provider<TherapistDashboardRepository>((ref) {
  return TherapistDashboardRepository(ref.watch(apiClientProvider));
});
