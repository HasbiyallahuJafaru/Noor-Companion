/// Streak state management.
///
/// [StreakNotifier] fetches the user's streak from GET /streaks/me and
/// exposes a refresh method so dhikr/duas screens can update the count
/// immediately after recording progress without navigating away.
///
/// [liveStreakProvider] is the single source of truth for streak UI across
/// all screens. home_providers.dart re-exports aliases from here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/domain/models/streak_model.dart';
import '../../data/streak_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StreakState {
  const StreakState({
    required this.streak,
    required this.isLoading,
    this.errorMessage,
  });

  final StreakModel streak;
  final bool isLoading;
  final String? errorMessage;

  StreakState copyWith({
    StreakModel? streak,
    bool? isLoading,
    String? errorMessage,
  }) =>
      StreakState(
        streak: streak ?? this.streak,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    _fetch();
    return StreakState(
      streak: const StreakModel(currentStreak: 0, longestStreak: 0, totalDays: 0),
      isLoading: true,
    );
  }

  /// Fetches the streak from the backend and updates state.
  Future<void> _fetch() async {
    try {
      final streak = await ref.read(streakRepositoryProvider).fetchMyStreak();
      state = state.copyWith(streak: streak, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Updates state immediately with [updated] data returned by
  /// POST /content/:id/progress, then silently re-fetches for consistency.
  ///
  /// Called by dhikr and duas screens right after recording progress
  /// so the streak counter updates without waiting for a round trip.
  void applyProgressResult(StreakModel updated) {
    state = state.copyWith(streak: updated, isLoading: false);
    _fetch();
  }

  /// Full refresh — used on app resume or after pull-to-refresh.
  Future<void> refresh() => _fetch();
}

final streakNotifierProvider =
    NotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);

// ── Convenience selectors ─────────────────────────────────────────────────────

/// Current streak day count. Used by StreakDisplay and home screen.
final liveStreakProvider = Provider<int>((ref) {
  return ref.watch(streakNotifierProvider).streak.currentStreak;
});

/// True when the current streak count is a milestone worth celebrating.
final liveIsMilestoneProvider = Provider<bool>((ref) {
  return ref.watch(streakNotifierProvider).streak.isMilestone;
});
