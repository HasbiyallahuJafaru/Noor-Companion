/// Milestone detail screen — congratulatory full-screen view shown when a
/// milestone badge is tapped from the progress screen.
/// Displays the badge large (120pt), virtue name in Arabic + English,
/// the related ayah via ArabicTextBlock, and a Continue button back home.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/arabic_text_block.dart';
import '../../domain/milestone.dart';
import '../widgets/milestone_badge.dart';

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen({super.key, required this.days});

  /// The milestone days value used to look up the milestone definition.
  final int days;

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> {
  @override
  void initState() {
    super.initState();
    // Celebrate with a strong haptic on arrival
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final milestone = milestoneForDays(widget.days);

    if (milestone == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Milestone not found.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                  tooltip: 'Close',
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
                      child: MilestageBadge(
                        milestone: milestone,
                        isUnlocked: true,
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      milestone.englishName,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${milestone.days} days of clarity',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.brandGold,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ArabicTextBlock(
                      arabic: milestone.arabicAyah,
                      transliteration: milestone.transliteration,
                      translation:
                          '${milestone.translation} (${milestone.reference})',
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'This is not a small thing. Every day you chose '
                      'remembrance over the pull — Allah witnessed it.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
