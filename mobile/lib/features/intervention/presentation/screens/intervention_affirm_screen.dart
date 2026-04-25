/// Intervention screen 4 — affirmation and exit.
/// Shows a warm, non-judgmental message acknowledging what the user just did.
/// Two options: call a therapist (navigates to Therapists tab) or return home.
/// Neither option is framed as more correct — no pressure either way.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class InterventionAffirmScreen extends StatelessWidget {
  const InterventionAffirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ornamental mark
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.tealLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.brandTeal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.brandTeal,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "You're doing well.",
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.brandTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'That took strength.',
                        style: AppTextStyles.headingLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Every moment you turn toward Allah instead of the pull '
                        'is a victory. Your nafs is learning a new path.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '﴿ وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا ﴾',
                        style: AppTextStyles.arabicMedium.copyWith(
                          color: AppColors.brandTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Those who strive for Us — We will guide them to Our paths.'
                        ' (29:69)',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Return Home'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Call a Therapist'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Spacer(),
          Text(
            '4 of 4',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
