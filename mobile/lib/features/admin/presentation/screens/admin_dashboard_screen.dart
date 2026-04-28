/// Admin dashboard — entry point for the admin panel.
/// Shows platform summary cards and navigation to each management section.
/// Only reachable by users with role = admin (enforced by GoRouter + API).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  analytics.when(
                    loading: () => const _AnalyticsShimmer(),
                    error: (e, _) => _ErrorCard(
                      message: e.toString(),
                      onRetry: () =>
                          ref.read(adminAnalyticsProvider.notifier).reload(),
                    ),
                    data: (data) => _AnalyticsGrid(data: data),
                  ),
                  const SizedBox(height: 32),
                  Text('Management', style: AppTextStyles.headingMedium),
                  const SizedBox(height: 16),
                  _ManagementSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Panel', style: AppTextStyles.headingLarge),
          Text('Platform management', style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          )),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () =>
              ref.read(adminAnalyticsProvider.notifier).reload(),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Analytics grid ─────────────────────────────────────────────────────────────

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.data});
  final AdminAnalytics data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          label: 'Total Users',
          value: _fmt(data.totalUsers),
          icon: Icons.people_rounded,
          color: AppColors.brandTeal,
        ),
        _StatCard(
          label: 'Active Today',
          value: _fmt(data.activeToday),
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFE67E22),
        ),
        _StatCard(
          label: 'Paid Subscribers',
          value: _fmt(data.paidSubscribers),
          icon: Icons.workspace_premium_rounded,
          color: AppColors.brandGold,
        ),
        _StatCard(
          label: 'Therapists',
          value: _fmt(data.totalTherapists),
          icon: Icons.health_and_safety_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Pending Review',
          value: _fmt(data.pendingTherapists),
          icon: Icons.hourglass_top_rounded,
          color: data.pendingTherapists > 0
              ? AppColors.error
              : AppColors.textMuted,
          highlight: data.pendingTherapists > 0,
        ),
        _StatCard(
          label: 'Calls This Month',
          value: _fmt(data.callSessionsThisMonth),
          icon: Icons.call_rounded,
          color: const Color(0xFF8E44AD),
        ),
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.3) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: highlight ? 0.12 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headingLarge.copyWith(
                  color: highlight ? color : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Management section ─────────────────────────────────────────────────────────

class _ManagementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementItem(
        label: 'Users',
        subtitle: 'Search, suspend, update tiers',
        icon: Icons.manage_accounts_rounded,
        color: AppColors.brandTeal,
        route: AppRoutes.adminUsers,
      ),
      _ManagementItem(
        label: 'Therapists',
        subtitle: 'Approve or reject applications',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.success,
        route: AppRoutes.adminTherapists,
      ),
      _ManagementItem(
        label: 'Content',
        subtitle: 'Add, toggle, manage dhikr & duas',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.brandGold,
        route: AppRoutes.adminContent,
      ),
      _ManagementItem(
        label: 'Broadcast',
        subtitle: 'Send push notifications to users',
        icon: Icons.campaign_rounded,
        color: const Color(0xFF8E44AD),
        route: AppRoutes.adminBroadcast,
      ),
    ];

    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ManagementCard(item: item),
              ))
          .toList(),
    );
  }
}

class _ManagementItem {
  const _ManagementItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.item});
  final _ManagementItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  )),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer / Error ────────────────────────────────────────────────────────────

class _AnalyticsShimmer extends StatelessWidget {
  const _AnalyticsShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('Failed to load analytics', style: AppTextStyles.body),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
