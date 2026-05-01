/// Home screen — premium light design with organic background,
/// glass cards, mood selector, streak, and Islamic content feed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../features/content/domain/models/dhikr_model.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/home_providers.dart';
import '../widgets/panic_button.dart';
import '../widgets/prayer_time_banner.dart';
import '../widgets/streak_display.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _moodIndex = -1;

  static const _moods = [
    ('😊', 'Great'),
    ('😌', 'Good'),
    ('😐', 'Okay'),
    ('😔', 'Not good'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(currentUserFirstNameProvider);
    final timeTag = ref.watch(timeOfDayTagProvider);
    final featuredAsync = ref.watch(featuredDhikrProvider);
    final morningAsync = ref.watch(morningDhikrProvider);
    final eveningAsync = ref.watch(eveningDhikrProvider);

    return Scaffold(
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _Header(firstName: firstName),
                            const SizedBox(height: 16),
                            const PrayerTimeBanner(),
                            const SizedBox(height: 20),
                            _MoodSelector(
                              moods: _moods,
                              selectedIndex: _moodIndex,
                              onSelect: (i) => setState(() => _moodIndex = i),
                            ),
                            const SizedBox(height: 20),
                            const StreakDisplay(),
                            const SizedBox(height: 24),
                            _SectionLabel(title: 'Daily Dhikr'),
                            const SizedBox(height: 12),
                            featuredAsync.when(
                              loading: () => const ShimmerBox(width: double.infinity, height: 130),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (item) => item != null
                                  ? _FeaturedDhikrCard(item: item)
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                            if (timeTag == 'morning' || timeTag == 'general') ...[
                              _SectionLabel(title: 'Morning Adhkar'),
                              const SizedBox(height: 12),
                              _DhikrRow(streamAsync: morningAsync),
                              const SizedBox(height: 24),
                            ],
                            if (timeTag == 'evening' || timeTag == 'general') ...[
                              _SectionLabel(title: 'Evening Adhkar'),
                              const SizedBox(height: 12),
                              _DhikrRow(streamAsync: eveningAsync),
                              const SizedBox(height: 24),
                            ],
                            _SectionLabel(title: 'Explore'),
                            const SizedBox(height: 12),
                            _QuickAccessRow(
                              onQuran: () => context.push(AppRoutes.quran),
                              onDuas: () => context.push(AppRoutes.duas),
                            ),
                            const SizedBox(height: 100),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: const PanicButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final name = firstName.isNotEmpty ? ', $firstName' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting$name 👋', style: AppTextStyles.headingLarge),
        const SizedBox(height: 4),
        Text('How are you feeling today?', style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ── Mood selector ─────────────────────────────────────────────────────────────

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.moods,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<(String, String)> moods;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(moods.length, (i) {
        final selected = selectedIndex == i;
        final (emoji, label) = moods[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < moods.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected
                      ? AppColors.brandTeal.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(
                    color: selected ? AppColors.brandTeal : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? AppColors.brandTeal : AppColors.textMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall);
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
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.arabicText,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.arabicLarge.copyWith(fontSize: 22),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.translation,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${item.targetCount}× · ${item.title}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.brandTeal, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dhikr horizontal row ──────────────────────────────────────────────────────

class _DhikrRow extends StatelessWidget {
  const _DhikrRow({required this.streamAsync});
  final AsyncValue<List<DhikrModel>> streamAsync;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: streamAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => const ShimmerBox(width: 110, height: 130),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (items) => ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
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
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: SizedBox(
          width: 110,
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
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${item.targetCount}×', style: AppTextStyles.caption.copyWith(color: AppColors.brandTeal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick access row ──────────────────────────────────────────────────────────

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({required this.onQuran, required this.onDuas});
  final VoidCallback onQuran;
  final VoidCallback onDuas;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickCard(icon: Icons.menu_book_rounded, label: 'Quran', sub: '114 surahs', onTap: onQuran)),
        const SizedBox(width: 12),
        Expanded(child: _QuickCard(icon: Icons.volunteer_activism_rounded, label: 'Duas', sub: 'Every occasion', onTap: onDuas)),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.label, required this.sub, required this.onTap});
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brandTeal, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(sub, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
