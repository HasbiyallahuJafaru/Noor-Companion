/// Content repository — fetches dhikr, duas, and recitations from the backend.
/// Returns cached data immediately on first yield, then refreshes in background.
/// Progress recording is fire-and-forget; streak data is returned on success.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../domain/models/dhikr_model.dart';
import '../domain/models/dua_model.dart';
import '../domain/models/recitation_model.dart';
import '../domain/models/streak_model.dart';
import 'content_cache.dart';

class ContentRepository {
  const ContentRepository(this._dio);

  final Dio _dio;

  /// Streams dhikr list — emits cached data first, then fresh from the API.
  Stream<List<DhikrModel>> watchDhikr({String? tag}) async* {
    final cached = getCachedDhikr();
    if (cached.isNotEmpty) yield cached;

    try {
      final response = await _dio.get(
        '/content/dhikr',
        queryParameters: tag != null ? {'tag': tag} : null,
      );
      final items = _parseList(response, DhikrModel.fromJson);
      await saveDhikr(items);
      yield items;
    } catch (_) {
      if (cached.isEmpty) rethrow;
    }
  }

  /// Streams duas list — emits cached data first, then fresh from the API.
  Stream<List<DuaModel>> watchDuas({String? tag}) async* {
    final cached = getCachedDuas();
    if (cached.isNotEmpty) yield cached;

    try {
      final response = await _dio.get(
        '/content/duas',
        queryParameters: tag != null ? {'tag': tag} : null,
      );
      final items = _parseList(response, DuaModel.fromJson);
      await saveDuas(items);
      yield items;
    } catch (_) {
      if (cached.isEmpty) rethrow;
    }
  }

  /// Streams recitations list — emits cached data first, then fresh.
  Stream<List<RecitationModel>> watchRecitations() async* {
    final cached = getCachedRecitations();
    if (cached.isNotEmpty) yield cached;

    try {
      final response = await _dio.get('/content/recitations');
      final items = _parseList(response, RecitationModel.fromJson);
      await saveRecitations(items);
      yield items;
    } catch (_) {
      if (cached.isEmpty) rethrow;
    }
  }

  /// Records that the user engaged with [contentId].
  /// Returns the updated [StreakModel] on success.
  Future<StreakModel> recordProgress(String contentId) async {
    final response = await _dio.post('/content/$contentId/progress');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return StreakModel.fromJson(data['streak'] as Map<String, dynamic>);
  }

  List<T> _parseList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(apiClientProvider));
});
