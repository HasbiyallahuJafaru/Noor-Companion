/// Dhikr library screen — grid of all dhikr items, filterable by tag.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/dhikr_provider.dart';
import '../widgets/dhikr_card.dart';

const _kTags = ['all', 'morning', 'evening', 'general', 'forgiveness'];

class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() =>
      _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  String _selectedTag = 'all';

  @override
  Widget build(BuildContext context) {
    final listAsync = _selectedTag == 'all'
        ? ref.watch(dhikrListProvider)
        : ref.watch(dhikrByTagProvider(_selectedTag));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dhikr'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tag filter chips ────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _kTags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tag = _kTags[i];
                final isSelected = tag == _selectedTag;
                return FilterChip(
                  label: Text(
                    tag[0].toUpperCase() + tag.substring(1),
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.brandTeal
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedTag = tag),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.tealLight,
                  checkmarkColor: AppColors.brandTeal,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.brandTeal
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── Content grid ─────────────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => const _DhikrGridSkeleton(),
              error: (e, _) => Center(
                child: Text('Failed to load dhikr',
                    style: AppTextStyles.bodySmall),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text('No dhikr found',
                          style: AppTextStyles.bodySmall),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => DhikrCard(
                        item: items[i],
                        onTap: () =>
                            context.push('/dhikr/${items[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DhikrGridSkeleton extends StatelessWidget {
  const _DhikrGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const ShimmerBox(width: double.infinity, height: double.infinity),
    );
  }
}
