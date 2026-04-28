/// Home screen — Islamic content feed with prayer times, streak, featured
/// dhikr, morning/evening adhkar rows, and the pinned "I'm Struggling" button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/content/domain/models/dhikr_model.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/home_providers.dart';
import '../widgets/panic_button.dart';
import '../widgets/prayer_time_banner.dart';
import '../widgets/streak_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(currentUserFirstNameProvider);
    final timeTag = ref.watch(timeOfDayTagProvider);
    final featuredAsync = ref.watch(featuredDhikrProvider);
    final morningAsync = ref.watch(morningDhikrProvider);
    final eveningAsync = ref.watch(eveningDhikrProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Greeting ──────────────────────────────────────
                        _Greeting(firstName: firstName),
                        const SizedBox(height: 16),
                        // ── Prayer times strip ────────────────────────────
                        const PrayerTimeBanner(),
                        const SizedBox(height: 24),
                        // ── Streak display ────────────────────────────────
                        const StreakDisplay(),
                        const SizedBox(height: 28),
                        // ── Featured dhikr ────────────────────────────────
                        _SectionHeader(title: 'Daily Dhikr'),
                        const SizedBox(height: 12),
                        featuredAsync.when(
                          loading: () => const ShimmerBox(
                              width: double.infinity, height: 120),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (item) => item != null
                              ? _FeaturedDhikrCard(item: item)
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),
                        // ── Morning adhkar row ────────────────────────────
                        if (timeTag == 'morning' || timeTag == 'general') ...[
                          _SectionHeader(
                            title: 'Morning Adhkar',
                            onSeeAll: () => context.push(AppRoutes.home),
                          ),
                          const SizedBox(height: 12),
                          _DhikrHorizontalRow(streamAsync: morningAsync),
                          const SizedBox(height: 28),
                        ],
                        // ── Evening adhkar row ────────────────────────────
                        if (timeTag == 'evening' || timeTag == 'general') ...[
                          _SectionHeader(
                            title: 'Evening Adhkar',
                            onSeeAll: () => context.push(AppRoutes.home),
                          ),
                          const SizedBox(height: 12),
                          _DhikrHorizontalRow(streamAsync: eveningAsync),
                          const SizedBox(height: 28),
                        ],
                        // ── Quran card ────────────────────────────────────
                        _SectionHeader(title: 'Quran'),
                        const SizedBox(height: 12),
                        _QuranCard(
                          onTap: () => context.push(AppRoutes.quran),
                        ),
                        const SizedBox(height: 28),
                        // ── Duas card ─────────────────────────────────────
                        _SectionHeader(title: 'Duas'),
                        const SizedBox(height: 12),
                        _DuasCard(
                          onTap: () => context.push(AppRoutes.duas),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // ── Panic button — always visible ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: const PanicButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final name = firstName.isNotEmpty ? ', $firstName' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum$name',
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: 2),
        Text(
          _subGreeting(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _subGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'May your night be full of peace.';
    if (hour < 12) return 'Start your day with remembrance.';
    if (hour < 15) return 'Keep the remembrance in your heart.';
    if (hour < 18) return 'Evening adhkar time is approaching.';
    return 'End your day with gratitude.';
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingSmall),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Featured dhikr card ───────────────────────────────────────────────────────

class _FeaturedDhikrCard extends StatelessWidget {
  const _FeaturedDhikrCard({required this.item});

  final DhikrModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dhikr/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.brandTeal,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.arabicText,
              textAlign: TextAlign.right,
              style: AppTextStyles.arabicLarge.copyWith(
                fontSize: 24,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              item.translation,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withAlpha(204),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${item.targetCount}× · ${item.title}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withAlpha(179),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dhikr horizontal row ──────────────────────────────────────────────────────

class _DhikrHorizontalRow extends StatelessWidget {
  const _DhikrHorizontalRow({required this.streamAsync});

  final AsyncValue<List<DhikrModel>> streamAsync;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: streamAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) =>
              const ShimmerBox(width: 120, height: 130),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _SmallDhikrCard(item: items[i]),
        ),
      ),
    );
  }
}

class _SmallDhikrCard extends StatelessWidget {
  const _SmallDhikrCard({required this.item});

  final DhikrModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dhikr/${item.id}'),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.arabicText,
              textAlign: TextAlign.right,
              style: AppTextStyles.arabicLarge.copyWith(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              item.title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${item.targetCount}×',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quran entry card ──────────────────────────────────────────────────────────

class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.brandTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quran Recitations',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Browse all 114 surahs',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Duas entry card ───────────────────────────────────────────────────────────

class _DuasCard extends StatelessWidget {
  const _DuasCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  color: AppColors.brandTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duas',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Supplications for every occasion',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
