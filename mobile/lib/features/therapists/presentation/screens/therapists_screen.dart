/// Therapists list screen — flat list with specialisation and language filter chips.
/// Fetches from the backend. Pull-to-refresh supported.
/// Empty/error states handled inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/therapists_provider.dart';
import '../widgets/therapist_card.dart';

class TherapistsScreen extends ConsumerWidget {
  const TherapistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTherapistsProvider);
    final filters = ref.watch(therapistFiltersProvider);
    final specialisations = ref.watch(availableSpecialisationsProvider);
    final languages = ref.watch(availableLanguagesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandTeal,
          onRefresh: () => ref.read(therapistsNotifierProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Therapists', style: AppTextStyles.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with someone who understands.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      _SearchBar(
                        query: filters.searchQuery,
                        onChanged: (q) => ref
                            .read(therapistFiltersProvider.notifier)
                            .setSearch(q),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // ── Filter chips ─────────────────────────────────────────────
              if (specialisations.isNotEmpty || languages.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: _FilterChipRow(
                      specialisations: specialisations,
                      languages: languages,
                      selectedSpecialisation: filters.specialisation,
                      selectedLanguage: filters.language,
                      onSpecialisation: (v) => ref
                          .read(therapistFiltersProvider.notifier)
                          .setSpecialisation(v),
                      onLanguage: (v) => ref
                          .read(therapistFiltersProvider.notifier)
                          .setLanguage(v),
                    ),
                  ),
                ),
              // ── List ────────────────────────────────────────────────────
              filteredAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandTeal),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: _ErrorState(
                    onRetry: () =>
                        ref.read(therapistsNotifierProvider.notifier).refresh(),
                  ),
                ),
                data: (therapists) => therapists.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(
                          hasFilters: filters.specialisation != null ||
                              filters.language != null ||
                              filters.searchQuery.isNotEmpty,
                          onClear: () =>
                              ref.read(therapistFiltersProvider.notifier).clearAll(),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        sliver: SliverList.separated(
                          itemCount: therapists.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              TherapistCard(therapist: therapists[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: 'Search by name…',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        suffixIcon: widget.query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 18),
                tooltip: 'Clear search',
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

// ── Filter chip row ───────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.specialisations,
    required this.languages,
    required this.selectedSpecialisation,
    required this.selectedLanguage,
    required this.onSpecialisation,
    required this.onLanguage,
  });

  final List<String> specialisations;
  final List<String> languages;
  final String? selectedSpecialisation;
  final String? selectedLanguage;
  final ValueChanged<String?> onSpecialisation;
  final ValueChanged<String?> onLanguage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...specialisations.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: _capitalize(s),
                  selected: s == selectedSpecialisation,
                  onTap: () => onSpecialisation(s),
                ),
              )),
          if (languages.isNotEmpty && specialisations.isNotEmpty)
            Container(
              width: 1,
              height: 24,
              color: AppColors.border,
              margin: const EdgeInsets.only(right: 8),
            ),
          ...languages.map((l) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: l,
                  selected: l == selectedLanguage,
                  onTap: () => onLanguage(l),
                ),
              )),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandTeal : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.brandTeal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No therapists match your filters.'
                  : 'No therapists available right now.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear filters',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Could not load therapists.\nCheck your connection and try again.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Retry',
                    style: AppTextStyles.button
                        .copyWith(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
