/// Admin content list screen — shows all dhikr, duas, and recitations.
/// Admin can toggle active/inactive and tap FAB to add new content.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminContentScreen extends ConsumerWidget {
  const AdminContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminContentProvider);
    final notifier = ref.read(adminContentProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Content', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminContentAdd),
        backgroundColor: AppColors.brandTeal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Content',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _CategoryFilter(
            current: state.categoryFilter,
            onChanged: notifier.setCategoryFilter,
          ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandTeal))
                : state.error != null
                    ? _ErrorView(error: state.error!, onRetry: notifier.load)
                    : state.items.isEmpty
                        ? const _EmptyView()
                        : _ContentList(
                            items: state.items,
                            onToggle: (item) => _toggle(context, ref, item),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    AdminContentItem item,
  ) async {
    final err = await ref
        .read(adminContentProvider.notifier)
        .toggleActive(item.id, isActive: !item.isActive);

    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }
}

// ── Category filter ────────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (null, 'All'),
      ('dhikr', 'Dhikr'),
      ('dua', 'Duas'),
      ('recitation', 'Recitations'),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: options
            .map((o) => _FilterChip(
                  label: o.$2,
                  isActive: current == o.$1,
                  onTap: () => onChanged(o.$1),
                ))
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandTeal : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.brandTeal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Content list ───────────────────────────────────────────────────────────────

class _ContentList extends StatelessWidget {
  const _ContentList({required this.items, required this.onToggle});

  final List<AdminContentItem> items;
  final ValueChanged<AdminContentItem> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ContentCard(
        item: items[i],
        onToggle: () => onToggle(items[i]),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item, required this.onToggle});

  final AdminContentItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(item.category);

    return Container(
      decoration: BoxDecoration(
        color: item.isActive ? AppColors.surface : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isActive ? AppColors.border : AppColors.borderDark,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_categoryIcon(item.category), color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: item.isActive
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniChip(label: item.category, color: catColor),
                    const SizedBox(width: 6),
                    ...item.tags.take(2).map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _MiniChip(
                                label: t, color: AppColors.textMuted),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: item.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isActive
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                item.isActive ? 'Active' : 'Off',
                style: AppTextStyles.caption.copyWith(
                  color: item.isActive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) => switch (cat) {
        'dhikr' => AppColors.brandTeal,
        'dua' => AppColors.brandGold,
        _ => const Color(0xFF8E44AD),
      };

  IconData _categoryIcon(String cat) => switch (cat) {
        'dhikr' => Icons.auto_awesome_rounded,
        'dua' => Icons.volunteer_activism_rounded,
        _ => Icons.menu_book_rounded,
      };
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty / Error ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No content items',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Tap + Add Content to create the first item.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
