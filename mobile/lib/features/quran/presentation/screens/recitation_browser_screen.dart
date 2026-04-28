/// Quran recitation browser — searchable list of all 114 surahs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/content/domain/models/recitation_model.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../providers/quran_provider.dart';

class RecitationBrowserScreen extends ConsumerStatefulWidget {
  const RecitationBrowserScreen({super.key});

  @override
  ConsumerState<RecitationBrowserScreen> createState() =>
      _RecitationBrowserScreenState();
}

class _RecitationBrowserScreenState
    extends ConsumerState<RecitationBrowserScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(recitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quran'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search surah name or number…',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: listAsync.when(
              loading: () => const _SurahListSkeleton(),
              error: (e, _) => Center(
                child: Text('Failed to load surahs',
                    style: AppTextStyles.bodySmall),
              ),
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((s) {
                        return s.nameEnglish
                                .toLowerCase()
                                .contains(_query) ||
                            s.nameArabic.contains(_query) ||
                            s.surahNumber.toString() == _query;
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No surahs found',
                        style: AppTextStyles.bodySmall),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _SurahTile(
                    item: filtered[i],
                    onTap: () => context
                        .push('/quran/${filtered[i].surahNumber}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Surah tile ────────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.item, required this.onTap});

  final RecitationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.tealLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.surahNumber}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEnglish,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.verseCount} verses · ${item.revelationType}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Arabic name
            Text(
              item.nameArabic,
              style: AppTextStyles.arabicLarge.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SurahListSkeleton extends StatelessWidget {
  const _SurahListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) =>
          const ShimmerBox(width: double.infinity, height: 64),
    );
  }
}
