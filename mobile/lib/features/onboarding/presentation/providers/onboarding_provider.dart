/// Riverpod state notifier for the onboarding flow.
/// Holds the user's answers across all 3 screens and persists
/// the completed state to Hive so the app skips onboarding on restart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/onboarding_state.dart';

const _hiveBoxName = 'onboarding';
const _hiveKey = 'completed';

/// Notifier that owns onboarding answers and persists completion to Hive.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Updates the selected addiction type. Pass null to clear the selection.
  void setAddictionType(AddictionType? type) {
    state = state.copyWith(addictionType: type);
  }

  /// Updates the selected journey stage.
  void setJourneyStage(JourneyStage stage) {
    state = state.copyWith(journeyStage: stage);
  }

  /// Updates whether the user wants therapist access.
  void setWantsTherapist({required bool wants}) {
    state = state.copyWith(wantsTherapist: wants);
  }

  /// Marks onboarding complete and writes the flag to Hive.
  /// Called after the user confirms screen 3.
  Future<void> complete() async {
    state = state.copyWith(isComplete: true);
    final box = await Hive.openBox<bool>(_hiveBoxName);
    await box.put(_hiveKey, true);
  }

  /// Returns true if the user has already completed onboarding.
  /// Read on app start to decide whether to show onboarding or home.
  static Future<bool> hasCompleted() async {
    final box = await Hive.openBox<bool>(_hiveBoxName);
    return box.get(_hiveKey, defaultValue: false) ?? false;
  }
}

/// Global provider for the onboarding flow state.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
