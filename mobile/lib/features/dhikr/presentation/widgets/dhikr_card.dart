/// Card widget for a single dhikr item in the library grid.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/content/domain/models/dhikr_model.dart';

class DhikrCard extends StatelessWidget {
  const DhikrCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final DhikrModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.arabicText,
                style: AppTextStyles.arabicLarge.copyWith(fontSize: 22),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.translation,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.targetCount}×',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.audioUrl != null)
                    const Icon(Icons.volume_up_rounded,
                        size: 14, color: AppColors.brandTeal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
