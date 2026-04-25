/// Therapist profile card used in the therapists list.
/// Shows avatar, name, specialty tag, availability dot, and rating.
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          therapist.name,
                          style: AppTextStyles.headingSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _AvailabilityDot(isAvailable: therapist.isAvailable),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _SpecialtyTag(specialty: therapist.specialty),
                  if (therapist.averageRating != null) ...[
                    const SizedBox(height: 6),
                    _RatingRow(
                      rating: therapist.averageRating!,
                      sessions: therapist.sessionCount,
                    ),
                  ],
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
                errorBuilder: (_, _, _) => _Initials(name: therapist.name),
              ),
            )
          : _Initials(name: therapist.name),
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

class _AvailabilityDot extends StatelessWidget {
  const _AvailabilityDot({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isAvailable ? 'Available now' : 'Not available',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAvailable ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SpecialtyTag extends StatelessWidget {
  const _SpecialtyTag({required this.specialty});

  final TherapistSpecialty specialty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tealXLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        specialty == TherapistSpecialty.counsellor
            ? 'Licensed Counsellor'
            : 'Islamic Scholar',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.sessions});

  final double rating;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.brandGold, size: 13),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' · $sessions sessions',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
