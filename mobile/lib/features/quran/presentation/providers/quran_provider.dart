/// Riverpod providers for the Quran feature.
/// recitationsProvider: streams surah list (cache-first).
/// surahDetailProvider: fetches a single surah with verses on demand.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/content/data/content_repository.dart';
import '../../../../features/content/data/islamic_repository.dart';
import '../../../../features/content/domain/models/recitation_model.dart';

// ── Surah list ────────────────────────────────────────────────────────────────

/// Streams the full 114-surah list. Emits cached items immediately.
final recitationsProvider = StreamProvider<List<RecitationModel>>((ref) {
  return ref.watch(contentRepositoryProvider).watchRecitations();
});

// ── Surah detail ──────────────────────────────────────────────────────────────

/// Fetches a single surah with verses by number (1–114).
final surahDetailProvider =
    FutureProvider.family<RecitationModel, int>((ref, surahNumber) async {
  return ref.watch(islamicRepositoryProvider).getSurah(surahNumber);
});
