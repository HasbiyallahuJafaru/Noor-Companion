/// Riverpod providers for the progress tab.
/// Stub weekly task data used until Phase 3 wires the real backend.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/milestone.dart';

/// True while progress data is being fetched. Defaults false (stub is immediate).
final progressIsLoadingProvider = Provider<bool>((_) => false);

/// Weekly task completion — one entry per day (Mon–Sun), 0.0–1.0 fraction.
/// Stub values until Phase 3 wires real streak/task history.
final weeklyCompletionProvider = Provider<List<double>>(
  (_) => [1.0, 0.67, 1.0, 0.33, 1.0, 0.67, 0.0],
);

/// Milestones unlocked by the current streak.
final unlockedMilestonesProvider = Provider<List<Milestone>>((ref) {
  final days = ref.watch(streakProvider);
  return unlockedMilestones(days);
});

/// All five milestones with their locked/unlocked state.
final allMilestonesProvider = Provider<List<({Milestone milestone, bool isUnlocked})>>((ref) {
  final days = ref.watch(streakProvider);
  return [
    for (final m in kMilestones)
      (milestone: m, isUnlocked: days >= m.days),
  ];
});
