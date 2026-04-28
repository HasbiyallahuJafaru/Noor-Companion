/// Therapist detail screen — full profile with subscription-gated call button.
/// Fetches the therapist from the backend via GET /api/v1/therapists/:id.
/// Paid users see "Start Call" (stubbed for Phase 5).
/// Free users see "Upgrade to Call" (stubbed for Phase 6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/therapist_model.dart';
import '../providers/therapists_provider.dart';

class TherapistDetailScreen extends ConsumerWidget {
  const TherapistDetailScreen({super.key, required this.therapistId});

  final String therapistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapistAsync = ref.watch(therapistByIdProvider(therapistId));

    return therapistAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandTeal),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Could not load therapist.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
      data: (therapist) => _DetailScaffold(therapist: therapist),
    );
  }
}

// ── Main scaffold ─────────────────────────────────────────────────────────────

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isPaid = auth is AuthAuthenticated && auth.user.isPaid;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    const SizedBox(height: 20),
                    _StatsRow(therapist: therapist),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'About',
                      child: Text(therapist.bio, style: AppTextStyles.body),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Specialisations',
                      child: _TagWrap(tags: therapist.specialisations),
                    ),
                    if (therapist.qualifications.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Qualifications',
                        child: _BulletList(items: therapist.qualifications),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Languages',
                      child: _TagWrap(
                        tags: therapist.languagesSpoken,
                        color: AppColors.goldLight,
                        textColor: AppColors.brandGoldDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Session Details',
                      child: _SessionDetails(therapist: therapist),
                    ),
                  ],
                ),
              ),
            ),
            _CallButton(therapist: therapist, isPaid: isPaid),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

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

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(therapist: therapist),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(therapist.fullName, style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text(
                '${therapist.yearsExperience} years experience',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Container(
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

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (therapist.averageRating != null) ...[
          _StatChip(
            icon: Icons.star_rounded,
            iconColor: AppColors.brandGold,
            label: '${therapist.averageRating!.toStringAsFixed(1)} rating',
          ),
          const SizedBox(width: 10),
        ],
        _StatChip(
          icon: Icons.headset_mic_rounded,
          iconColor: AppColors.brandTeal,
          label: '${therapist.totalSessions} sessions',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headingSmall),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ── Tag wrap ──────────────────────────────────────────────────────────────────

class _TagWrap extends StatelessWidget {
  const _TagWrap({
    required this.tags,
    this.color = AppColors.tealXLight,
    this.textColor = AppColors.brandTeal,
  });

  final List<String> tags;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) {
        final display = t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            display,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Bullet list ───────────────────────────────────────────────────────────────

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(item, style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Session details ───────────────────────────────────────────────────────────

class _SessionDetails extends StatelessWidget {
  const _SessionDetails({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined,
              color: AppColors.brandGold, size: 20),
          const SizedBox(width: 12),
          Text(
            '₦${_formatRate(therapist.sessionRateNgn)} per session',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRate(int rate) {
    if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(rate % 1000 == 0 ? 0 : 1)}k';
    }
    return rate.toString();
  }
}

// ── Call button ───────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  const _CallButton({required this.therapist, required this.isPaid});

  final TherapistModel therapist;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: isPaid ? _PaidCallButton(therapist: therapist) : _UpgradeButton(),
    );
  }
}

class _PaidCallButton extends StatelessWidget {
  const _PaidCallButton({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Agora call flow wired in Phase 5
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling — coming in Phase 5'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.call_rounded, size: 20),
      label: const Text('Start Call'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goldLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.brandGold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.brandGold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upgrade to Noor Companion Premium to call therapists.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brandGoldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Subscription flow wired in Phase 6
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription flow — coming in Phase 6'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGold,
            minimumSize: const Size(double.infinity, 52),
          ),
          child: const Text('Upgrade to Call'),
        ),
      ],
    );
  }
}
