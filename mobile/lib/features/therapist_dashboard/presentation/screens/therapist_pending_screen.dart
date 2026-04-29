/// Shown to a therapist whose application status is 'pending' or 'rejected'.
/// Communicates current status clearly and prompts next steps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/therapist_dashboard_provider.dart';

class TherapistPendingScreen extends ConsumerWidget {
  const TherapistPendingScreen({super.key, required this.isRejected, this.rejectionReason});

  final bool isRejected;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusIcon(isRejected: isRejected),
              const SizedBox(height: 32),
              Text(
                isRejected ? 'Application Not Approved' : 'Application Under Review',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Unfortunately your application could not be approved at this time.'
                    : 'Our team is reviewing your application. You\'ll receive a notification once a decision is made — usually within 2–3 business days.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (isRejected && rejectionReason != null) ...[
                const SizedBox(height: 24),
                _RejectionReasonCard(reason: rejectionReason!),
              ],
              const SizedBox(height: 40),
              _RefreshButton(
                onTap: () => ref.read(therapistProfileProvider.notifier).load(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status icon ───────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isRejected});
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    final color = isRejected ? AppColors.error : AppColors.brandGold;
    final icon = isRejected ? Icons.cancel_outlined : Icons.hourglass_empty_rounded;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}

// ── Rejection reason card ─────────────────────────────────────────────────────

class _RejectionReasonCard extends StatelessWidget {
  const _RejectionReasonCard({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(reason, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.brandTeal,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandTeal.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Check Status',
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
