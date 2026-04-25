/// Weekly task completion bar chart.
/// Seven bars (Mon–Sun), each filling to the day's completion fraction.
/// Today's bar is highlighted teal; past bars are muted; future bars are empty.
/// No external chart library — drawn with pure Flutter layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/progress_providers.dart';

class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(weeklyCompletionProvider);
    // 0 = Monday … 6 = Sunday; DateTime.weekday 1=Mon…7=Sun
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This Week', style: AppTextStyles.headingSmall),
              const Spacer(),
              Text(
                '${(data.fold(0.0, (a, b) => a + b) / data.length * 100).round()}% avg',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final fraction = i < data.length ? data[i] : 0.0;
                final isToday = i == todayIndex;
                final isFuture = i > todayIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Bar(
                      fraction: fraction,
                      label: _dayLabels[i],
                      isToday: isToday,
                      isFuture: isFuture,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.label,
    required this.isToday,
    required this.isFuture,
  });

  final double fraction;
  final String label;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final filledColor = isFuture
        ? AppColors.border
        : isToday
            ? AppColors.brandTeal
            : AppColors.brandTeal.withValues(alpha: 0.45);

    return Semantics(
      label: '$label: ${(fraction * 100).round()}% complete',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  flex: ((1 - fraction) * 100).round().clamp(0, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: (fraction * 100).round().clamp(1, 100),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: filledColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(fraction >= 1.0 ? 4 : 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isToday ? AppColors.brandTeal : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isToday ? Colors.white : AppColors.textMuted,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
