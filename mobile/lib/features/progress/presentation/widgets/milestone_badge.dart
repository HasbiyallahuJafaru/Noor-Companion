/// Milestone badge widget — 72pt circle showing an Islamic virtue name.
/// Locked: grey fill, lock icon, muted label.
/// Unlocked: gold fill, gold glow, Arabic virtue name, tappable.
/// Used in the progress screen badge grid and the milestone detail screen.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/milestone.dart';

class MilestageBadge extends StatelessWidget {
  const MilestageBadge({
    super.key,
    required this.milestone,
    required this.isUnlocked,
    this.onTap,
    this.size = 72,
  });

  final Milestone milestone;
  final bool isUnlocked;

  /// Called when an unlocked badge is tapped. Null suppresses tap.
  final VoidCallback? onTap;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isUnlocked
          ? '${milestone.englishName} — unlocked'
          : '${milestone.englishName} — locked. Reach ${milestone.days} days.',
      button: isUnlocked && onTap != null,
      child: GestureDetector(
        onTap: isUnlocked ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BadgeCircle(
              milestone: milestone,
              isUnlocked: isUnlocked,
              size: size,
            ),
            const SizedBox(height: 6),
            Text(
              '${milestone.days}d',
              style: AppTextStyles.caption.copyWith(
                color: isUnlocked
                    ? AppColors.brandGold
                    : AppColors.textMuted,
                fontWeight:
                    isUnlocked ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({
    required this.milestone,
    required this.isUnlocked,
    required this.size,
  });

  final Milestone milestone;
  final bool isUnlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? AppColors.goldLight : AppColors.backgroundSecondary,
        border: Border.all(
          color: isUnlocked ? AppColors.brandGold : AppColors.border,
          width: isUnlocked ? 2.5 : 1.5,
        ),
        boxShadow: isUnlocked ? AppShadows.goldGlow : null,
      ),
      child: isUnlocked
          ? Center(
              child: Text(
                milestone.arabicName,
                style: AppTextStyles.arabicMedium.copyWith(
                  color: AppColors.brandGold,
                  fontSize: size * 0.28,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Center(
              child: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted,
                size: size * 0.36,
              ),
            ),
    );
  }
}
