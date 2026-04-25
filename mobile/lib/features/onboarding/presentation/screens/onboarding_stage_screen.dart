/// Onboarding screen 2 — journey stage selection.
/// User selects how long they have been on their recovery journey.
/// Selection stored via onboardingProvider. No skip — all options are
/// non-stigmatising so one must be chosen, but a back path exists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/selection_card.dart';

class OnboardingStageScreen extends ConsumerWidget {
  const OnboardingStageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      stepIndex: 1,
      totalSteps: 3,
      title: 'How long have you\nbeen on this journey?',
      subtitle: 'This helps us set the right pace for your recovery.',
      onContinue: () => context.go('/onboarding/therapist'),
      isContinueEnabled: state.journeyStage != null,
      children: [
        _StageOption(
          label: 'Just starting',
          subtitle: 'Day 1 — taking the first step',
          stage: JourneyStage.justStarting,
          selected: state.journeyStage,
          onTap: notifier.setJourneyStage,
        ),
        const SizedBox(height: 12),
        _StageOption(
          label: 'A few weeks',
          subtitle: 'Building early momentum',
          stage: JourneyStage.fewWeeks,
          selected: state.journeyStage,
          onTap: notifier.setJourneyStage,
        ),
        const SizedBox(height: 12),
        _StageOption(
          label: 'A few months',
          subtitle: 'Establishing new habits',
          stage: JourneyStage.fewMonths,
          selected: state.journeyStage,
          onTap: notifier.setJourneyStage,
        ),
        const SizedBox(height: 12),
        _StageOption(
          label: 'Over a year',
          subtitle: 'Maintaining and deepening',
          stage: JourneyStage.overAYear,
          selected: state.journeyStage,
          onTap: notifier.setJourneyStage,
        ),
      ],
    );
  }
}

class _StageOption extends StatelessWidget {
  const _StageOption({
    required this.label,
    required this.subtitle,
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final JourneyStage stage;
  final JourneyStage? selected;
  final void Function(JourneyStage) onTap;

  @override
  Widget build(BuildContext context) {
    return SelectionCard(
      label: label,
      subtitle: subtitle,
      isSelected: selected == stage,
      onTap: () => onTap(stage),
    );
  }
}
