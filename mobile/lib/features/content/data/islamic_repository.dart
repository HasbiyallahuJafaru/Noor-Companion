/// Islamic content repository — prayer times and Quran surah detail.
/// All data is fetched from the backend, which proxies external APIs with Redis
/// caching. The Flutter layer caches prayer times in memory for the session.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../domain/models/prayer_times_model.dart';
import '../domain/models/recitation_model.dart';

class IslamicRepository {
  const IslamicRepository(this._dio);

  final Dio _dio;

  /// Fetches prayer times for the given coordinates.
  /// [date] is optional — defaults to today on the backend.
  Future<PrayerTimesModel> getPrayerTimes({
    required double lat,
    required double lng,
    String? date,
  }) async {
    final response = await _dio.get(
      '/islamic/prayer-times',
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        // ignore: use_null_aware_elements
        if (date != null) 'date': date,
      },
    );
    final data =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return PrayerTimesModel.fromJson(data);
  }

  /// Fetches full surah [number] with Arabic text, translation, and audio URL.
  Future<RecitationModel> getSurah(int number) async {
    final response = await _dio.get('/islamic/quran/$number');
    final data =
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return RecitationModel.fromJson(data);
  }
}

final islamicRepositoryProvider = Provider<IslamicRepository>((ref) {
  return IslamicRepository(ref.watch(apiClientProvider));
});
