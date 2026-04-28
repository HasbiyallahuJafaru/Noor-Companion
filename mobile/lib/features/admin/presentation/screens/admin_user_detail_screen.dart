/// Admin user detail screen — full profile for a single user.
/// Allows the admin to suspend/restore or manually adjust subscription tier.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminUserDetailProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('User Detail', style: AppTextStyles.headingMedium),
      ),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandTeal),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(adminUserDetailProvider(userId)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandTeal),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (user) => _UserDetailBody(user: user),
      ),
    );
  }
}

class _UserDetailBody extends ConsumerWidget {
  const _UserDetailBody({required this.user});
  final AdminUserDetail user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          _StreakCard(user: user),
          const SizedBox(height: 24),
          Text('Actions', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          _ActionCard(user: user),
        ],
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: user.fullName, isActive: user.isActive),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Badge(label: user.role, color: roleColor),
                        const SizedBox(width: 8),
                        if (user.isPaid)
                          _Badge(
                              label: 'Paid',
                              color: AppColors.brandGold),
                        if (!user.isActive) ...[
                          const SizedBox(width: 8),
                          _Badge(
                              label: 'Suspended',
                              color: AppColors.error),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(label: 'User ID', value: user.id),
          _InfoRow(label: 'Supabase ID', value: user.supabaseId),
          _InfoRow(
            label: 'Joined',
            value: _fmt(user.createdAt),
          ),
          _InfoRow(
            label: 'Subscription',
            value: user.subscriptionTier.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
        'admin' => const Color(0xFF8E44AD),
        'therapist' => AppColors.success,
        _ => AppColors.brandTeal,
      };

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

// ── Streak card ────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.user});
  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    if (user.currentStreak == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Streak', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _StreakStat(
                  label: 'Current',
                  value: '${user.currentStreak ?? 0}'),
              _StreakStat(
                  label: 'Longest',
                  value: '${user.longestStreak ?? 0}'),
              _StreakStat(
                  label: 'Total Days',
                  value: '${user.totalDays ?? 0}'),
            ],
          ),
          if (user.lastEngagedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last active ${_relativeDate(user.lastEngagedAt!)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w800,
              )),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }
}

// ── Action card ────────────────────────────────────────────────────────────────

class _ActionCard extends ConsumerWidget {
  const _ActionCard({required this.user});
  final AdminUserDetail user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ActionButton(
            label: user.isActive ? 'Suspend Account' : 'Restore Account',
            icon: user.isActive
                ? Icons.block_rounded
                : Icons.check_circle_outline_rounded,
            color: user.isActive ? AppColors.error : AppColors.success,
            onTap: () => _toggleActive(context, ref),
          ),
          const SizedBox(height: 12),
          if (!user.isPaid)
            _ActionButton(
              label: 'Grant Paid Access',
              icon: Icons.workspace_premium_rounded,
              color: AppColors.brandGold,
              onTap: () => _grantPaid(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final action = user.isActive ? 'Suspend' : 'Restore';
    final confirm = await _confirm(
      context,
      title: '$action Account',
      body: user.isActive
          ? 'This prevents them from logging in.'
          : 'This allows them to log in again.',
      confirmLabel: action,
      confirmColor:
          user.isActive ? AppColors.error : AppColors.success,
    );
    if (!confirm || !context.mounted) return;

    final err = await ref
        .read(adminUsersProvider.notifier)
        .toggleUserActive(user.id, isActive: !user.isActive);

    if (context.mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _grantPaid(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Grant Paid Access',
      body: 'Manually upgrade this user to the paid tier.',
      confirmLabel: 'Grant',
      confirmColor: AppColors.brandGold,
    );
    if (!confirm || !context.mounted) return;

    try {
      await ref.read(adminRepositoryProvider).updateUser(
            user.id,
            subscriptionTier: 'paid',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paid tier granted.')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update tier.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isActive});
  final String name;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.brandTeal.withValues(alpha: 0.15)
            : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: AppTextStyles.headingSmall.copyWith(
              color: isActive ? AppColors.brandTeal : AppColors.textMuted,
            )),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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
