/// Daily task card — displays a single task with a completion checkbox.
/// Tapping anywhere on the card toggles completion via tasksProvider.
/// Completed state: teal fill, checkmark, label struck through.
/// Haptic feedback fires on toggle (lightImpact).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onToggle});

  final TaskModel task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: task.isCompleted,
      label: '${task.label}. ${task.estimatedMinutes} minutes.'
          '${task.isCompleted ? ' Completed.' : ' Tap to mark complete.'}',
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: task.isCompleted ? AppColors.tealLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: task.isCompleted ? AppColors.brandTeal : AppColors.border,
            width: task.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _CategoryIcon(category: task.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.label,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: task.isCompleted
                          ? AppColors.brandTeal
                          : AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '~${task.estimatedMinutes} min',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Checkbox(isChecked: task.isCompleted),
          ],
        ),
      ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final TaskCategory category;

  IconData get _icon => switch (category) {
        TaskCategory.dhikr => Icons.radio_button_checked_rounded,
        TaskCategory.quran => Icons.menu_book_rounded,
        TaskCategory.prayer => Icons.mosque_rounded,
        TaskCategory.physical => Icons.directions_walk_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.tealXLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(_icon, color: AppColors.brandTeal, size: 20),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? AppColors.brandTeal : Colors.transparent,
        border: Border.all(
          color: isChecked ? AppColors.brandTeal : AppColors.border,
          width: 2,
        ),
      ),
      child: isChecked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}
