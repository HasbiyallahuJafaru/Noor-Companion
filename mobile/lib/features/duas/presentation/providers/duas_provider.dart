/// Riverpod providers for the duas feature.
/// duasListProvider: streams full duas list (cache-first).
/// duasByOccasionProvider: filters by occasion tag.
/// duaBookmarkProvider: tracks bookmarked dua IDs with toggle support.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/content/data/content_cache.dart';
import '../../../../features/content/data/content_repository.dart';
import '../../../../features/content/domain/models/dua_model.dart';

// ── List ──────────────────────────────────────────────────────────────────────

/// Streams the full duas library. Emits cached items immediately.
final duasListProvider = StreamProvider<List<DuaModel>>((ref) {
  return ref.watch(contentRepositoryProvider).watchDuas();
});

/// Duas filtered by occasion tag (morning, eating, anxiety, etc.).
final duasByOccasionProvider =
    StreamProvider.family<List<DuaModel>, String>((ref, occasion) {
  return ref.watch(contentRepositoryProvider).watchDuas(tag: occasion);
});

// ── Bookmarks ─────────────────────────────────────────────────────────────────

/// Tracks which dua IDs are bookmarked. Persisted to Hive.
class DuaBookmarkNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => getBookmarkedDuaIds();

  /// Toggles bookmark for [duaId]. Returns whether it is now bookmarked.
  Future<bool> toggle(String duaId) async {
    final isNow = await toggleDuaBookmark(duaId);
    state = getBookmarkedDuaIds();
    return isNow;
  }

  bool isBookmarked(String duaId) => state.contains(duaId);
}

final duaBookmarkProvider =
    NotifierProvider<DuaBookmarkNotifier, Set<String>>(
  DuaBookmarkNotifier.new,
);
