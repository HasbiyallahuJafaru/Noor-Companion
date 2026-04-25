/// Onboarding screen 1 — addiction type selection.
/// User selects what they are working through, or skips entirely.
/// Selection is stored to Hive via the onboarding provider.
/// No shame framing: "Prefer not to say" is a first-class option.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/selection_card.dart';

class OnboardingAddictionScreen extends ConsumerWidget {
  const OnboardingAddictionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      stepIndex: 0,
      totalSteps: 3,
      title: 'What are you\nworking through?',
      subtitle: 'This helps us personalise your experience. '
          'You can always change this later.',
      onContinue: () => context.go('/onboarding/stage'),
      onSkip: () {
        notifier.setAddictionType(null);
        context.go('/onboarding/stage');
      },
      isContinueEnabled: true,
      children: [
        _AddictionOption(
          label: 'Alcohol',
          type: AddictionType.alcohol,
          selected: state.addictionType,
          onTap: notifier.setAddictionType,
        ),
        const SizedBox(height: 12),
        _AddictionOption(
          label: 'Drugs',
          type: AddictionType.drugs,
          selected: state.addictionType,
          onTap: notifier.setAddictionType,
        ),
        const SizedBox(height: 12),
        _AddictionOption(
          label: 'Prescription medication',
          type: AddictionType.prescription,
          selected: state.addictionType,
          onTap: notifier.setAddictionType,
        ),
        const SizedBox(height: 12),
        _AddictionOption(
          label: 'Prefer not to say',
          type: AddictionType.preferNotToSay,
          selected: state.addictionType,
          onTap: notifier.setAddictionType,
        ),
      ],
    );
  }
}

class _AddictionOption extends StatelessWidget {
  const _AddictionOption({
    required this.label,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AddictionType type;
  final AddictionType? selected;
  final void Function(AddictionType?) onTap;

  @override
  Widget build(BuildContext context) {
    return SelectionCard(
      label: label,
      isSelected: selected == type,
      onTap: () => onTap(type),
    );
  }
}
