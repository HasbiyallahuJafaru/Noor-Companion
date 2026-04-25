/// Prayer time banner — a slim strip showing the next prayer name and a
/// stub countdown. Non-intrusive, teal-light background. Tapping opens
/// the device clock app. Real prayer times are wired in Phase 2.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

class PrayerTimeBanner extends StatelessWidget {
  const PrayerTimeBanner({super.key});

  Future<void> _openClock() async {
    final uri = Uri.parse('clockapp://');
    if (!await launchUrl(uri)) {
      // Silently fail — this is a convenience tap, not a critical action
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openClock,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.tealLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: AppColors.brandTeal,
            ),
            const SizedBox(width: 8),
            Text(
              'Next prayer: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Asr', // Stub — replaced with real data in Phase 2
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'in 1h 24m', // Stub countdown
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandTeal,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
