/// Onboarding screen 3 — therapist preference.
/// User opts in or defers therapist access. No hard gate — "Maybe later"
/// is always available and the feature can be enabled from the Therapists tab.
/// On confirm, marks onboarding complete and navigates to home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/selection_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingTherapistScreen extends ConsumerWidget {
  const OnboardingTherapistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      stepIndex: 2,
      totalSteps: 3,
      title: 'Would you like access\nto a therapist?',
      subtitle: 'Connect with a real human when you need one most.',
      isContinueEnabled: true,
      onContinue: () async {
        await notifier.complete();
        if (context.mounted) context.go('/home');
      },
      children: [
        SelectionCard(
          label: 'Yes, connect me',
          subtitle: 'I may want to call a therapist during difficult moments.',
          isSelected: state.wantsTherapist,
          onTap: () => notifier.setWantsTherapist(wants: true),
        ),
        const SizedBox(height: 12),
        SelectionCard(
          label: 'Maybe later',
          subtitle: 'I\'ll decide when I\'m ready.',
          isSelected: !state.wantsTherapist,
          onTap: () => notifier.setWantsTherapist(wants: false),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Licensed counsellors and Islamic scholars available on demand.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.brandTeal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
