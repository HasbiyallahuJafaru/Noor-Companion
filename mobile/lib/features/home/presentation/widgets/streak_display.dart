/// Streak display widget — shows the user's "days of clarity" counter with a
/// teal progress arc. On milestone days (7, 30, 90, 180, 365) the arc turns
/// gold and a soft glow signals the achievement.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';

class StreakDisplay extends ConsumerWidget {
  const StreakDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakProvider);
    final isMilestone = ref.watch(isMilestoneDayProvider);

    final label = isMilestone
        ? '$days days of clarity. Milestone reached.'
        : '$days days of clarity.';

    return Semantics(
      label: label,
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: isMilestone ? AppShadows.goldGlow : AppShadows.sm,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _ArcPainter(
                    days: days,
                    isMilestone: isMilestone,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$days',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: isMilestone
                            ? AppColors.brandGold
                            : AppColors.brandTeal,
                        fontSize: 40,
                      ),
                    ),
                    Text(
                      'days',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMilestone ? '✦ Milestone reached' : 'days of clarity',
            style: AppTextStyles.bodySmall.copyWith(
              color: isMilestone ? AppColors.brandGold : AppColors.textMuted,
              fontWeight: isMilestone ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Paints the background track and the filled arc proportional to progress
/// toward the next milestone.
class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.days, required this.isMilestone});

  final int days;
  final bool isMilestone;

  /// Returns the progress fraction (0.0–1.0) toward the next milestone.
  double _progress() {
    const milestones = [7, 30, 90, 180, 365];
    for (final m in milestones) {
      if (days <= m) return days / m;
    }
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * _progress();

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = isMilestone ? AppColors.brandGold : AppColors.brandTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centre, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.days != days || old.isMilestone != isMilestone;
}
