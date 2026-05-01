/// Persistent app shell with floating glass bottom navigation bar.
/// Role-based tabs: user, therapist, admin — all with Profile tab.
/// Notification bell pinned top-right across all tabs.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/dhikr/presentation/screens/dhikr_library_screen.dart';
import '../../features/quran/presentation/screens/recitation_browser_screen.dart';
import '../../features/therapists/presentation/screens/therapists_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/therapist_dashboard/presentation/screens/therapist_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/permissions_service.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _TabDef {
  const _TabDef({required this.icon, required this.label, required this.widget});
  final IconData icon;
  final String label;
  final Widget widget;
}

const _userTabs = [
  _TabDef(icon: Icons.home_rounded, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: Icons.auto_awesome_rounded, label: 'Dhikr', widget: DhikrLibraryScreen()),
  _TabDef(icon: Icons.menu_book_rounded, label: 'Quran', widget: RecitationBrowserScreen()),
  _TabDef(icon: Icons.people_outline_rounded, label: 'Therapists', widget: TherapistsScreen()),
  _TabDef(icon: Icons.person_outline_rounded, label: 'Profile', widget: ProfileScreen()),
];

const _therapistTabs = [
  _TabDef(icon: Icons.home_rounded, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: Icons.auto_awesome_rounded, label: 'Dhikr', widget: DhikrLibraryScreen()),
  _TabDef(icon: Icons.dashboard_rounded, label: 'Dashboard', widget: TherapistDashboardScreen()),
  _TabDef(icon: Icons.person_outline_rounded, label: 'Profile', widget: ProfileScreen()),
];

const _adminTabs = [
  _TabDef(icon: Icons.home_rounded, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: Icons.admin_panel_settings_rounded, label: 'Admin', widget: AdminDashboardScreen()),
  _TabDef(icon: Icons.menu_book_rounded, label: 'Quran', widget: RecitationBrowserScreen()),
  _TabDef(icon: Icons.person_outline_rounded, label: 'Profile', widget: ProfileScreen()),
];

// ── Shell ──────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(PermissionsService.requestAppPermissions);
    Future.microtask(() => ref.read(notificationsProvider.notifier).load());
  }

  List<_TabDef> get _tabs {
    final auth = ref.watch(authProvider);
    if (auth is AuthAuthenticated && auth.user.isAdmin) return _adminTabs;
    if (auth is AuthAuthenticated && auth.user.isTherapist) return _therapistTabs;
    return _userTabs;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final tabs = _tabs;
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: tabs.map((t) => t.widget).toList(),
          ),
          // Notification bell overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: _NotificationBell(
                  unreadCount: unreadCount,
                  onTap: () => context.push('/notifications'),
                ),
              ),
            ),
          ),
          // Floating glass nav
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _FloatingNav(
              tabs: tabs,
              currentIndex: safeIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating glass nav ────────────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabDef> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandTeal.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: active
                        ? BoxDecoration(
                            color: AppColors.brandTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          )
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: active ? 22 : 20,
                          color: active ? AppColors.brandTeal : AppColors.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tabs[i].label,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: active ? AppColors.brandTeal : AppColors.textMuted,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Notification bell ──────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, required this.onTap});
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                  color: unreadCount > 0 ? AppColors.brandTeal : AppColors.textSecondary,
                  size: 20,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53E3E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
