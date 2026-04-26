/// Riverpod providers for the dhikr feature.
/// dhikrListProvider: streams the list from cache then API.
/// dhikrCounterProvider: local counter state per dhikr item (offline-capable).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/content/data/content_repository.dart';
import '../../../../features/content/domain/models/dhikr_model.dart';
import '../../../../features/content/domain/models/streak_model.dart';

// ── List ──────────────────────────────────────────────────────────────────────

/// Streams the full dhikr library. Emits cached items immediately.
final dhikrListProvider =
    StreamProvider<List<DhikrModel>>((ref) {
  return ref.watch(contentRepositoryProvider).watchDhikr();
});

/// Streams dhikr filtered to a specific tag (morning, evening, etc.).
final dhikrByTagProvider =
    StreamProvider.family<List<DhikrModel>, String>((ref, tag) {
  return ref.watch(contentRepositoryProvider).watchDhikr(tag: tag);
});

// ── Counter ───────────────────────────────────────────────────────────────────

/// Tracks the tap count for a single dhikr session.
/// Keyed by dhikr item id so each detail screen has its own counter.
class DhikrCounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Increments the counter by one.
  void tap() => state = state + 1;

  /// Resets the counter to zero.
  void reset() => state = 0;
}

final dhikrCounterProvider =
    NotifierProvider.family<DhikrCounterNotifier, int, String>(
  DhikrCounterNotifier.new,
);

// ── Progress recording ────────────────────────────────────────────────────────

/// Records a completed dhikr session for [contentId].
/// Returns [StreakModel] on success so the UI can show streak updates.
Future<StreakModel> recordDhikrProgress(
    WidgetRef ref, String contentId) async {
  return ref.read(contentRepositoryProvider).recordProgress(contentId);
}
