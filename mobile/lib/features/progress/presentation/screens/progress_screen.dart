/// Progress tab — shows streak summary, weekly task completion chart,
/// and the five milestone badges in a grid (locked/unlocked state).
/// Empty state shown when no data yet (new user).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeletons.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/progress_providers.dart';
import '../widgets/milestone_badge.dart';
import '../widgets/weekly_chart.dart';
import '../../domain/milestone.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(progressIsLoadingProvider);
    final days = ref.watch(streakProvider);
    final milestones = ref.watch(allMilestonesProvider);

    if (isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(child: ProgressScreenSkeleton()),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Your journey at a glance.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    _StreakSummaryCard(days: days),
                    const SizedBox(height: 16),
                    const WeeklyChart(),
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'Milestones'),
                    const SizedBox(height: 4),
                    Text(
                      'Earned through days of clarity.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: SliverToBoxAdapter(
                child: _MilestonesGrid(
                  milestones: milestones,
                  context: context,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard({required this.days});

  final int days;

  String get _message {
    if (days == 0) return 'Your journey starts today.';
    if (days < 7) return 'Every day counts. Keep going.';
    if (days < 30) return 'One week down. Your nafs is learning.';
    if (days < 90) return 'A full month of clarity. MashaAllah.';
    if (days < 180) return 'Three months strong. Istiqamah.';
    if (days < 365) return 'Six months of light. Almost there.';
    return 'One year. A transformation rooted in faith.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandTeal,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$days',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 48,
                ),
              ),
              Text(
                'days clean',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              _message,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestonesGrid extends StatelessWidget {
  const _MilestonesGrid({
    required this.milestones,
    required this.context,
  });

  final List<({Milestone milestone, bool isUnlocked})> milestones;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 20,
      alignment: WrapAlignment.start,
      children: milestones.map((entry) {
        return MilestageBadge(
          milestone: entry.milestone,
          isUnlocked: entry.isUnlocked,
          onTap: entry.isUnlocked
              ? () {
                  HapticFeedback.heavyImpact();
                  context.push('/milestone/${entry.milestone.days}');
                }
              : null,
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall);
  }
}
