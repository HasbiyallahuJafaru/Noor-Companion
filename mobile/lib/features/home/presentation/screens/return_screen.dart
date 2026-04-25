/// Return screen — shown when a user resets their streak after a relapse.
/// Never a cold reset. Always leads with mercy: "Tawbah is always open."
/// Shows an ayah on repentance, then a soft "Start again" button.
/// The streak resets to 0 only after the user taps "Start again" —
/// they are never punished silently.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/arabic_text_block.dart';

class ReturnScreen extends ConsumerWidget {
  const ReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.textMuted,
                  tooltip: 'Back',
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                AppColors.brandTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.water_drop_outlined,
                          color: AppColors.brandTeal,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Tawbah is always open.',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.brandTeal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Returning to Allah after a stumble is not weakness — '
                      'it is exactly what He asks of you. '
                      'Every moment of return is beloved to Him.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const ArabicTextBlock(
                      arabic:
                          'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
                      transliteration:
                          "Qul yā ʿibādiya lladhīna asrafū ʿalā anfusihim lā taqnaṭū min raḥmati llāh",
                      translation:
                          'Say: O My servants who have transgressed against themselves — '
                          'do not despair of the mercy of Allah. (39:53)',
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Your counter will reset to zero. '
                      'That number is not your worth — it is just a measure '
                      'of the days ahead.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _StartAgainButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartAgainButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        // Streak reset will call streakProvider.notifier.reset() in Phase 3.
        // For now navigate home — the provider is read-only stub.
        context.go(AppRoutes.home);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: const Text('Start again — بِسْمِ اللَّهِ'),
    );
  }
}
