/// Admin user list screen — searchable, filterable list of all platform users.
/// Tap a user to open their detail screen. Long-press for quick suspend/restore.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../providers/admin_provider.dart';
import '../../domain/admin_models.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Users', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (q) => notifier.search(q),
          ),
          _FilterRow(state: state, notifier: notifier),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.brandTeal))
                : state.error != null
                    ? _ErrorView(error: state.error!, onRetry: notifier.load)
                    : state.users.isEmpty
                        ? const _EmptyView()
                        : _UserList(
                            users: state.users,
                            onTap: (u) => context.push(
                              AppRoutes.adminUserDetail
                                  .replaceFirst(':id', u.id),
                            ),
                            onToggleActive: (u) =>
                                _confirmToggle(context, ref, u),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final action = user.isActive ? 'Suspend' : 'Restore';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action ${user.fullName}?'),
        content: Text(
          user.isActive
              ? 'This will prevent them from logging in.'
              : 'This will allow them to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  user.isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final err = await ref
        .read(adminUsersProvider.notifier)
        .toggleUserActive(user.id, isActive: !user.isActive);

    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name…',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(Icons.clear_rounded,
                      color: AppColors.textMuted),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

// ── Filter row ─────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state, required this.notifier});
  final AdminUsersState state;
  final AdminUsersNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: 'All roles',
            isActive: state.roleFilter == null,
            onTap: () => notifier.setRoleFilter(null),
          ),
          _Chip(
            label: 'Users',
            isActive: state.roleFilter == 'user',
            onTap: () => notifier.setRoleFilter('user'),
          ),
          _Chip(
            label: 'Therapists',
            isActive: state.roleFilter == 'therapist',
            onTap: () => notifier.setRoleFilter('therapist'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Free',
            isActive: state.tierFilter == 'free',
            onTap: () => notifier.setTierFilter(
              state.tierFilter == 'free' ? null : 'free',
            ),
          ),
          _Chip(
            label: 'Paid',
            isActive: state.tierFilter == 'paid',
            onTap: () => notifier.setTierFilter(
              state.tierFilter == 'paid' ? null : 'paid',
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandTeal : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.brandTeal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── User list ──────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  const _UserList({
    required this.users,
    required this.onTap,
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final ValueChanged<AdminUser> onTap;
  final ValueChanged<AdminUser> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UserCard(
        user: users[i],
        onTap: () => onTap(users[i]),
        onToggleActive: () => onToggleActive(users[i]),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onToggleActive,
  });

  final AdminUser user;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: user.isActive ? AppColors.surface : AppColors.border,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Avatar(name: user.fullName, isActive: user.isActive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: user.isActive
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (!user.isActive)
                        _Badge(label: 'Suspended', color: AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(label: user.role, color: roleColor),
                      const SizedBox(width: 6),
                      if (user.isPaid)
                        _Badge(label: 'Paid', color: AppColors.brandGold),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleActive,
              child: Icon(
                user.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                color: user.isActive ? AppColors.error : AppColors.success,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    return switch (role) {
      'admin' => const Color(0xFF8E44AD),
      'therapist' => AppColors.success,
      _ => AppColors.brandTeal,
    };
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.brandTeal.withValues(alpha: 0.15)
            : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.brandTeal : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
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
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Empty / Error ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No users found', style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
          )),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error,
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandTeal),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
