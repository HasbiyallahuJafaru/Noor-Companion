/// Therapist repository — fetches the directory from the backend.
/// Supports optional specialisation and language filters.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/therapist_model.dart';

class TherapistRepository {
  const TherapistRepository(this._dio);

  final dynamic _dio;

  /// Fetches a page of active therapists.
  /// [specialisation] and [language] are optional filter values.
  ///
  /// Returns the list only — pagination metadata is discarded here
  /// because the UI loads all pages via the notifier's load-more logic.
  Future<List<TherapistModel>> fetchTherapists({
    String? specialisation,
    String? language,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'specialisation': specialisation,
      'language': language,
    }..removeWhere((_, v) => v == null);

    final response = await _dio.get(
      '/therapists',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['therapists'] as List<dynamic>;
    return list
        .map((e) => TherapistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single therapist's full profile by their TherapistProfile ID.
  Future<TherapistModel> fetchTherapistById(String therapistProfileId) async {
    final response = await _dio.get('/therapists/$therapistProfileId');
    final data = response.data['data'] as Map<String, dynamic>;
    return TherapistModel.fromJson(data);
  }
}

final therapistRepositoryProvider = Provider<TherapistRepository>((ref) {
  return TherapistRepository(ref.watch(apiClientProvider));
});
