/// Three-layer Arabic text display block.
/// Layer 1: Arabic phrase in Amiri serif — large, RTL, visually prominent.
/// Layer 2: Latin transliteration in Inter italic — 14sp, muted.
/// Layer 3: English translation in Inter — 15sp, dark body text.
/// Used in: intervention dua screen, dhikr detail, milestone screen.
/// Accessibility: semanticsLabel reads the English translation so screen
/// readers announce meaning rather than attempting to pronounce Arabic.
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

class ArabicTextBlock extends StatelessWidget {
  const ArabicTextBlock({
    super.key,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.showDivider = true,
  });

  /// The Arabic text — rendered RTL in Amiri serif at 28sp minimum.
  final String arabic;

  /// Latin phonetic transliteration shown below the Arabic.
  final String transliteration;

  /// English meaning shown below the transliteration.
  final String translation;

  /// Whether to show a faint horizontal divider below the block.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: translation,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.tealXLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic — RTL, large serif, centred
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                arabic,
                style: AppTextStyles.arabicLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _Divider(),
            const SizedBox(height: 16),
            // Transliteration
            Text(
              transliteration,
              style: AppTextStyles.transliteration,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Translation
            Text(
              translation,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showDivider) ...[
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '✦',
            style: TextStyle(
              color: AppColors.brandTeal.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}
