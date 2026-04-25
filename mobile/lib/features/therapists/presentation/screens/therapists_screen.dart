/// Therapists list screen — the Therapists tab content.
/// Two sections: Counsellors and Islamic Scholars.
/// Search bar filters both sections by name (client-side).
/// Empty section states shown when search returns no results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/therapists_provider.dart';
import '../widgets/therapist_card.dart';

class TherapistsScreen extends ConsumerWidget {
  const TherapistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counsellors = ref.watch(filteredCounsellorsProvider);
    final scholars = ref.watch(filteredScholarsProvider);
    final query = ref.watch(therapistSearchProvider);

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
                    Text('Therapists', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Connect with someone who understands.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    _SearchBar(
                      query: query,
                      onChanged: (q) => ref
                          .read(therapistSearchProvider.notifier)
                          .update(q),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            // Counsellors section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(title: 'Counsellors'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: counsellors.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptySection(query: query),
                    )
                  : SliverList.separated(
                      itemCount: counsellors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          TherapistCard(therapist: counsellors[i]),
                    ),
            ),
            // Islamic Scholars section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(title: 'Islamic Scholars'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              sliver: scholars.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptySection(query: query),
                    )
                  : SliverList.separated(
                      itemCount: scholars.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          TherapistCard(therapist: scholars[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headingSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.tealXLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        query.isEmpty
            ? 'No therapists available right now.'
            : 'No results for "$query".',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
