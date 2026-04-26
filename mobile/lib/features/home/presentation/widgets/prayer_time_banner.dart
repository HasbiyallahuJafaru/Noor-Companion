/// Prayer time banner — shows next prayer name and live countdown.
/// Requests location on mount. When permission is denied, shows an
/// "Enable location" prompt that opens app settings.
/// When cached times are displayed due to a network error, shows a subtle note.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/prayer_times_provider.dart';

class PrayerTimeBanner extends ConsumerWidget {
  const PrayerTimeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(prayerTimesProvider);

    return prayerAsync.when(
      loading: () => const _BannerSkeleton(),
      error: (_, _) => const _BannerSkeleton(),
      data: (state) => switch (state) {
        PrayerTimesLoading() => const _BannerSkeleton(),
        PrayerTimesLocationDenied() => _LocationDeniedBanner(
            onEnable: () =>
                ref.read(prayerTimesProvider.notifier).openSettingsAndRetry(),
          ),
        PrayerTimesLoaded(:final times, :final isCached) => _TimeBanner(
            times: times,
            isCached: isCached,
          ),
        PrayerTimesError(:final cached) => cached != null
            ? _TimeBanner(times: cached, isCached: true)
            : const _LocationDeniedBanner(),
      },
    );
  }
}

// ── Loaded state ──────────────────────────────────────────────────────────────

class _TimeBanner extends ConsumerWidget {
  const _TimeBanner({required this.times, required this.isCached});

  final dynamic times;
  final bool isCached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(nextPrayerCountdownProvider).asData?.value;
    final now = DateTime.now();
    final nextName = (times as dynamic).nextPrayerName(now) as String;
    final countdownText = _formatCountdown(countdown);

    return Container(
      height: 48,
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
            'Next: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            nextName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.brandTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isCached)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'cached',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Text(
            countdownText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.brandTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(int? seconds) {
    if (seconds == null) return '––';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Location denied state ─────────────────────────────────────────────────────

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner({this.onEnable});

  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            'Prayer times need location access',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (onEnable != null)
            GestureDetector(
              onTap: onEnable,
              child: Text(
                'Enable',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
