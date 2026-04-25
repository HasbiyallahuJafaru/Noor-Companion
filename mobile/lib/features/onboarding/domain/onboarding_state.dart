/// Onboarding data collected across the 3-screen flow.
/// Persisted to Hive local storage on completion so it survives app restarts.
/// All fields are nullable — the user may skip any question.
library;

/// The addiction type the user is working through, as selected on screen 1.
enum AddictionType {
  alcohol,
  drugs,
  prescription,
  preferNotToSay,
}

/// How long the user has been on their recovery journey, selected on screen 2.
enum JourneyStage {
  justStarting,
  fewWeeks,
  fewMonths,
  overAYear,
}

/// Collected onboarding answers. Immutable — create a copy to update.
class OnboardingState {
  const OnboardingState({
    this.addictionType,
    this.journeyStage,
    this.wantsTherapist = false,
    this.isComplete = false,
  });

  final AddictionType? addictionType;
  final JourneyStage? journeyStage;

  /// True if the user selected "Yes, connect me" on screen 3.
  final bool wantsTherapist;

  /// True once the user has completed or skipped all 3 screens.
  final bool isComplete;

  OnboardingState copyWith({
    AddictionType? addictionType,
    JourneyStage? journeyStage,
    bool? wantsTherapist,
    bool? isComplete,
  }) {
    return OnboardingState(
      addictionType: addictionType ?? this.addictionType,
      journeyStage: journeyStage ?? this.journeyStage,
      wantsTherapist: wantsTherapist ?? this.wantsTherapist,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
