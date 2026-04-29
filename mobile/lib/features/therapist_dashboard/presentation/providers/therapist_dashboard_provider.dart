/// Riverpod providers for the therapist dashboard.
/// Covers own-profile state and session history pagination.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../data/therapist_dashboard_repository.dart';
import '../../domain/therapist_dashboard_models.dart';

// ── Own profile ───────────────────────────────────────────────────────────────

/// All states for the therapist's own profile load.
sealed class TherapistProfileState {
  const TherapistProfileState();
}

class TherapistProfileLoading extends TherapistProfileState {
  const TherapistProfileLoading();
}

class TherapistProfileLoaded extends TherapistProfileState {
  const TherapistProfileLoaded(this.profile);
  final TherapistOwnProfile profile;
}

class TherapistProfileError extends TherapistProfileState {
  const TherapistProfileError(this.message);
  final String message;
}

class TherapistProfileNotifier extends Notifier<TherapistProfileState> {
  @override
  TherapistProfileState build() {
    Future.microtask(load);
    return const TherapistProfileLoading();
  }

  /// Loads the therapist's own profile from the backend.
  Future<void> load() async {
    state = const TherapistProfileLoading();
    try {
      final repo = ref.read(therapistDashboardRepositoryProvider);
      final profile = await repo.fetchMyProfile();
      state = TherapistProfileLoaded(profile);
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      state = TherapistProfileError(
        e.response?.data?['error']?['message'] as String? ??
            'Failed to load profile.',
      );
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      state = TherapistProfileError('Failed to load profile.');
    }
  }

  /// Submits a profile update. Re-loads the profile on success.
  ///
  /// @returns error message string, or null on success
  Future<String?> updateProfile({
    required String bio,
    required List<String> specialisations,
    required List<String> qualifications,
    required List<String> languagesSpoken,
    required int yearsExperience,
    required int sessionRateNgn,
  }) async {
    try {
      final repo = ref.read(therapistDashboardRepositoryProvider);
      await repo.updateProfile(
        bio: bio,
        specialisations: specialisations,
        qualifications: qualifications,
        languagesSpoken: languagesSpoken,
        yearsExperience: yearsExperience,
        sessionRateNgn: sessionRateNgn,
      );
      await load();
      return null;
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      return e.response?.data?['error']?['message'] as String? ??
          'Failed to update profile.';
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      return 'Failed to update profile.';
    }
  }
}

final therapistProfileProvider =
    NotifierProvider<TherapistProfileNotifier, TherapistProfileState>(
  TherapistProfileNotifier.new,
);

// ── Session history ───────────────────────────────────────────────────────────

/// State for the paginated session history list.
class SessionHistoryState {
  const SessionHistoryState({
    required this.sessions,
    required this.isLoading,
    required this.hasMore,
    required this.page,
    this.errorMessage,
  });

  final List<CallSessionSummary> sessions;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  SessionHistoryState copyWith({
    List<CallSessionSummary>? sessions,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? errorMessage,
  }) {
    return SessionHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: errorMessage,
    );
  }
}

class SessionHistoryNotifier extends Notifier<SessionHistoryState> {
  @override
  SessionHistoryState build() {
    Future.microtask(loadFirst);
    return const SessionHistoryState(
      sessions: [],
      isLoading: true,
      hasMore: false,
      page: 0,
    );
  }

  /// Loads the first page, replacing any existing list.
  Future<void> loadFirst() async {
    state = const SessionHistoryState(
      sessions: [],
      isLoading: true,
      hasMore: false,
      page: 0,
    );
    await _loadPage(1);
  }

  /// Loads the next page and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    await _loadPage(state.page + 1);
  }

  Future<void> _loadPage(int page) async {
    try {
      final repo = ref.read(therapistDashboardRepositoryProvider);
      final result = await repo.fetchSessionHistory(page: page);
      final updated = [
        if (page > 1) ...state.sessions,
        ...result.sessions,
      ];
      state = SessionHistoryState(
        sessions: updated,
        isLoading: false,
        hasMore: result.hasMore,
        page: page,
      );
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['error']?['message'] as String? ??
            'Failed to load sessions.',
      );
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load sessions.',
      );
    }
  }
}

final sessionHistoryProvider =
    NotifierProvider<SessionHistoryNotifier, SessionHistoryState>(
  SessionHistoryNotifier.new,
);
