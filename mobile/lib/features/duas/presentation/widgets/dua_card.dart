/// Card widget for a single dua in the duas library list.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/content/domain/models/dua_model.dart';

class DuaCard extends StatelessWidget {
  const DuaCard({
    super.key,
    required this.item,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkToggle,
  });

  final DuaModel item;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onBookmarkToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isBookmarked
                          ? AppColors.brandTeal
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.arabicText,
              style: AppTextStyles.arabicLarge.copyWith(fontSize: 18),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              item.translation,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _OccasionChip(occasion: item.occasion),
                const Spacer(),
                if (item.audioUrl != null)
                  const Icon(Icons.volume_up_rounded,
                      size: 14, color: AppColors.brandTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.occasion});

  final String occasion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        occasion[0].toUpperCase() + occasion.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
