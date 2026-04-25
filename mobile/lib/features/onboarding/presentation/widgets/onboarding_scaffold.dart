/// Shared layout scaffold for all three onboarding screens.
/// Provides consistent padding, step indicator, title/subtitle, scrollable
/// content area, and a sticky bottom CTA + skip link.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onContinue,
    this.onSkip,
    this.isContinueEnabled = true,
  });

  /// 0-based index of the current step.
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onContinue;

  /// If null, the skip link is not shown.
  final VoidCallback? onSkip;

  final bool isContinueEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: stepIndex, total: totalSteps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppTextStyles.headingLarge),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppTextStyles.body),
                    const SizedBox(height: 32),
                    ...children,
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _BottomActions(
              onContinue: onContinue,
              onSkip: onSkip,
              isContinueEnabled: isContinueEnabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i <= current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandTeal : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onContinue,
    required this.isContinueEnabled,
    this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback? onSkip;
  final bool isContinueEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: isContinueEnabled ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text('Continue', style: AppTextStyles.button),
          ),
          if (onSkip != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSkip,
              child: Center(
                child: Text(
                  'Skip',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
