/// Therapist detail screen — full profile with Call Now button.
/// Call Now is enabled only when therapist isAvailable.
/// Disabled state shows "Not available right now" label.
/// Call flow (Agora RTC) is wired in Phase 5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/therapist_model.dart';
import '../providers/therapists_provider.dart';

class TherapistDetailScreen extends ConsumerWidget {
  const TherapistDetailScreen({super.key, required this.therapistId});

  final String therapistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapist = ref.watch(therapistByIdProvider(therapistId));

    if (therapist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Therapist not found.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(therapist: therapist),
                    const SizedBox(height: 28),
                    _InfoRow(therapist: therapist),
                    const SizedBox(height: 24),
                    Text('About', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 10),
                    Text(therapist.bio, style: AppTextStyles.body),
                    const SizedBox(height: 32),
                    _AvailabilityBanner(isAvailable: therapist.isAvailable),
                  ],
                ),
              ),
            ),
            _CallButton(therapist: therapist),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Large avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLight,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: therapist.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    therapist.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _InitialsFallback(name: therapist.name),
                  ),
                )
              : _InitialsFallback(name: therapist.name),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(therapist.name, style: AppTextStyles.headingMedium),
              const SizedBox(height: 6),
              _SpecialtyChip(specialty: therapist.specialty),
              const SizedBox(height: 6),
              Row(
                children: [
                  _AvailabilityDot(isAvailable: therapist.isAvailable),
                  const SizedBox(width: 6),
                  Text(
                    therapist.isAvailable
                        ? 'Available now'
                        : 'Not available',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: therapist.isAvailable
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.headingMedium.copyWith(
          color: AppColors.brandTeal,
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.specialty});

  final TherapistSpecialty specialty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _AvailabilityDot extends StatelessWidget {
  const _AvailabilityDot({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAvailable ? AppColors.success : AppColors.textMuted,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (therapist.averageRating != null)
          _InfoChip(
            icon: Icons.star_rounded,
            iconColor: AppColors.brandGold,
            label:
                '${therapist.averageRating!.toStringAsFixed(1)} rating',
          ),
        if (therapist.averageRating != null) const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.headset_mic_rounded,
          iconColor: AppColors.brandTeal,
          label: '${therapist.sessionCount} sessions',
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tealXLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    if (isAvailable) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This therapist is not available right now. '
              'Check back later or choose another.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ElevatedButton.icon(
        onPressed: therapist.isAvailable
            ? () {
                // Agora call flow wired in Phase 5
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling — coming in Phase 5'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.call_rounded, size: 20),
        label: Text(
          therapist.isAvailable ? 'Call Now' : 'Not available right now',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }
}
