/// Therapist profile card used in the therapists list.
/// Shows avatar, name, top 2 specialisations, rating, and session rate.
/// Tapping navigates to the therapist detail screen.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/therapist_model.dart';

class TherapistCard extends StatelessWidget {
  const TherapistCard({super.key, required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/therapists/${therapist.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            _Avatar(therapist: therapist),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    therapist.fullName,
                    style: AppTextStyles.headingSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _SpecialisationTags(tags: therapist.topSpecialisations),
                  const SizedBox(height: 6),
                  _MetaRow(therapist: therapist),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.tealLight,
        border: Border.all(color: AppColors.border),
      ),
      child: therapist.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                therapist.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _Initials(name: therapist.fullName),
              ),
            )
          : _Initials(name: therapist.fullName),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.brandTeal,
        ),
      ),
    );
  }
}

// ── Specialisation tags ───────────────────────────────────────────────────────

class _SpecialisationTags extends StatelessWidget {
  const _SpecialisationTags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) => _Tag(label: t)).toList(),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final display = label.isEmpty
        ? label
        : label[0].toUpperCase() + label.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tealXLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        display,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Meta row — rating + rate ──────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (therapist.averageRating != null) ...[
          const Icon(Icons.star_rounded,
              color: AppColors.brandGold, size: 13),
          const SizedBox(width: 3),
          Text(
            therapist.averageRating!.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' · ${therapist.totalSessions} sessions',
            style: AppTextStyles.caption,
          ),
          const SizedBox(width: 10),
        ],
        Text(
          '₦${_formatRate(therapist.sessionRateNgn)}/session',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatRate(int rate) {
    if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(rate % 1000 == 0 ? 0 : 1)}k';
    }
    return rate.toString();
  }
}
