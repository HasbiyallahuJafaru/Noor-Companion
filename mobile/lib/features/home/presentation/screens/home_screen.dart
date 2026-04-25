/// Home screen — the primary daily view for recovery users.
/// Layout: greeting → prayer banner → streak display → today's tasks.
/// The "I'm Struggling" panic button is pinned above the bottom nav bar
/// and is always visible without scrolling on any supported screen size.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/home_providers.dart';
import '../widgets/panic_button.dart';
import '../widgets/prayer_time_banner.dart';
import '../widgets/streak_display.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final allDone = ref.watch(allTasksDoneProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Scrollable content ──────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _Greeting(),
                        const SizedBox(height: 16),
                        const PrayerTimeBanner(),
                        const SizedBox(height: 24),
                        const StreakDisplay(),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: "Today's Tasks",
                          trailing: allDone ? "Masha'Allah ✓" : null,
                        ),
                        const SizedBox(height: 12),
                        if (allDone)
                          _AllDoneCard()
                        else
                          ...tasks.map((task) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskCard(task: task),
                              )),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // ── Panic button — always visible, pinned above nav bar ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: const PanicButton(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Personalised greeting. Reads time of day to show the appropriate salutation.
/// Name placeholder — replaced with real user data in Phase 1.
class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = switch (hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.brandTeal,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(salutation, style: AppTextStyles.headingLarge),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingSmall),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.brandTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Empty state shown when all tasks are completed for the day.
class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.brandTeal, size: 32),
          const SizedBox(height: 8),
          Text(
            "You're done for today.",
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep going — every day of remembrance is a gift to your nafs.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
