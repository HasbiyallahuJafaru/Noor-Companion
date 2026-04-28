/// Riverpod providers for the therapists feature.
/// TherapistsNotifier fetches from the backend and supports
/// specialisation + language filter chips.
/// Search query filters client-side by name after fetch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/therapist_repository.dart';
import '../../domain/therapist_model.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

class TherapistFilters {
  const TherapistFilters({
    this.specialisation,
    this.language,
    this.searchQuery = '',
  });

  final String? specialisation;
  final String? language;
  final String searchQuery;

  TherapistFilters copyWith({
    String? specialisation,
    String? language,
    String? searchQuery,
    bool clearSpecialisation = false,
    bool clearLanguage = false,
  }) =>
      TherapistFilters(
        specialisation: clearSpecialisation ? null : (specialisation ?? this.specialisation),
        language: clearLanguage ? null : (language ?? this.language),
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

final therapistFiltersProvider =
    NotifierProvider<_FiltersNotifier, TherapistFilters>(_FiltersNotifier.new);

class _FiltersNotifier extends Notifier<TherapistFilters> {
  @override
  TherapistFilters build() => const TherapistFilters();

  void setSpecialisation(String? value) {
    state = value == state.specialisation
        ? state.copyWith(clearSpecialisation: true)
        : state.copyWith(specialisation: value);
  }

  void setLanguage(String? value) {
    state = value == state.language
        ? state.copyWith(clearLanguage: true)
        : state.copyWith(language: value);
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void clearAll() => state = const TherapistFilters();
}

// ── Therapist list notifier ───────────────────────────────────────────────────

class TherapistsNotifier extends AsyncNotifier<List<TherapistModel>> {
  @override
  Future<List<TherapistModel>> build() => _fetch();

  Future<List<TherapistModel>> _fetch() {
    final filters = ref.watch(therapistFiltersProvider);
    return ref.read(therapistRepositoryProvider).fetchTherapists(
          specialisation: filters.specialisation,
          language: filters.language,
        );
  }

  /// Re-fetches the list — used on pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final therapistsNotifierProvider =
    AsyncNotifierProvider<TherapistsNotifier, List<TherapistModel>>(
  TherapistsNotifier.new,
);

// ── Filtered + searched list ──────────────────────────────────────────────────

/// Applies the client-side name search on top of the server-filtered list.
final filteredTherapistsProvider = Provider<AsyncValue<List<TherapistModel>>>((ref) {
  final listAsync = ref.watch(therapistsNotifierProvider);
  final query = ref.watch(therapistFiltersProvider).searchQuery.toLowerCase().trim();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where((t) => t.fullName.toLowerCase().contains(query))
        .toList();
  });
});

// ── Single therapist lookup ───────────────────────────────────────────────────

/// Fetches a single therapist by ID — used by the detail screen.
final therapistByIdProvider =
    FutureProvider.family<TherapistModel, String>((ref, id) {
  return ref.read(therapistRepositoryProvider).fetchTherapistById(id);
});

// ── Distinct filter chip options ──────────────────────────────────────────────

/// All unique specialisations from the loaded list, sorted alphabetically.
final availableSpecialisationsProvider = Provider<List<String>>((ref) {
  final listAsync = ref.watch(therapistsNotifierProvider);
  return listAsync.maybeWhen(
    data: (list) {
      final all = list.expand((t) => t.specialisations).toSet().toList();
      all.sort();
      return all;
    },
    orElse: () => [],
  );
});

/// All unique languages from the loaded list, sorted alphabetically.
final availableLanguagesProvider = Provider<List<String>>((ref) {
  final listAsync = ref.watch(therapistsNotifierProvider);
  return listAsync.maybeWhen(
    data: (list) {
      final all = list.expand((t) => t.languagesSpoken).toSet().toList();
      all.sort();
      return all;
    },
    orElse: () => [],
  );
});
