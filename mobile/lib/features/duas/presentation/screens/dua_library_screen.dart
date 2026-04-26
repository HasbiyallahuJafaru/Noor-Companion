/// Duas library screen — scrollable list of duas, filterable by occasion.
/// Bookmark state is persisted to Hive via DuaBookmarkNotifier.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/duas_provider.dart';
import '../widgets/dua_card.dart';

const _kOccasions = [
  'all',
  'morning',
  'evening',
  'eating',
  'anxiety',
  'travel',
  'general',
];

class DuaLibraryScreen extends ConsumerStatefulWidget {
  const DuaLibraryScreen({super.key});

  @override
  ConsumerState<DuaLibraryScreen> createState() => _DuaLibraryScreenState();
}

class _DuaLibraryScreenState extends ConsumerState<DuaLibraryScreen> {
  String _selectedOccasion = 'all';

  @override
  Widget build(BuildContext context) {
    final listAsync = _selectedOccasion == 'all'
        ? ref.watch(duasListProvider)
        : ref.watch(duasByOccasionProvider(_selectedOccasion));
    final bookmarks = ref.watch(duaBookmarkProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duas'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Occasion filter chips ───────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _kOccasions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final occasion = _kOccasions[i];
                final isSelected = occasion == _selectedOccasion;
                return FilterChip(
                  label: Text(
                    occasion[0].toUpperCase() + occasion.substring(1),
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.brandTeal
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedOccasion = occasion),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.tealLight,
                  checkmarkColor: AppColors.brandTeal,
                  side: BorderSide(
                    color: isSelected ? AppColors.brandTeal : AppColors.border,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── Content list ──────────────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => const _DuaListSkeleton(),
              error: (e, _) => Center(
                child: Text('Failed to load duas',
                    style: AppTextStyles.bodySmall),
              ),
              data: (items) => items.isEmpty
                  ? Center(
                      child: Text('No duas found',
                          style: AppTextStyles.bodySmall),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return DuaCard(
                          item: item,
                          isBookmarked: bookmarks.contains(item.id),
                          onTap: () => context.push('/duas/${item.id}'),
                          onBookmarkToggle: () => ref
                              .read(duaBookmarkProvider.notifier)
                              .toggle(item.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaListSkeleton extends StatelessWidget {
  const _DuaListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ShimmerBox(width: double.infinity, height: 120),
    );
  }
}
