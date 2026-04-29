/// Persistent app shell with bottom navigation bar.
/// Four main tabs for users/therapists: Home, Dhikr, Quran, Therapists.
/// Admin users get a fifth Admin tab instead of Therapists.
/// A notifications bell icon is shown at top-right of every tab with an unread badge.
/// Each tab preserves its navigation state across switches via IndexedStack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/dhikr/presentation/screens/dhikr_library_screen.dart';
import '../../features/quran/presentation/screens/recitation_browser_screen.dart';
import '../../features/therapists/presentation/screens/therapists_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/therapist_dashboard/presentation/screens/therapist_dashboard_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Tab definitions ────────────────────────────────────────────────────────────

class _TabDef {
  const _TabDef({
    required this.icon,
    required this.label,
    required this.widget,
  });

  final IconData icon;
  final String label;
  final Widget widget;
}

const _userTabs = [
  _TabDef(
    icon: Icons.home_rounded,
    label: 'Home',
    widget: HomeScreen(),
  ),
  _TabDef(
    icon: Icons.auto_awesome_rounded,
    label: 'Dhikr',
    widget: DhikrLibraryScreen(),
  ),
  _TabDef(
    icon: Icons.menu_book_rounded,
    label: 'Quran',
    widget: RecitationBrowserScreen(),
  ),
  _TabDef(
    icon: Icons.people_outline_rounded,
    label: 'Therapists',
    widget: TherapistsScreen(),
  ),
];

const _therapistTabs = [
  _TabDef(
    icon: Icons.home_rounded,
    label: 'Home',
    widget: HomeScreen(),
  ),
  _TabDef(
    icon: Icons.auto_awesome_rounded,
    label: 'Dhikr',
    widget: DhikrLibraryScreen(),
  ),
  _TabDef(
    icon: Icons.menu_book_rounded,
    label: 'Quran',
    widget: RecitationBrowserScreen(),
  ),
  _TabDef(
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
    widget: TherapistDashboardScreen(),
  ),
];

const _adminTabs = [
  _TabDef(
    icon: Icons.home_rounded,
    label: 'Home',
    widget: HomeScreen(),
  ),
  _TabDef(
    icon: Icons.auto_awesome_rounded,
    label: 'Dhikr',
    widget: DhikrLibraryScreen(),
  ),
  _TabDef(
    icon: Icons.menu_book_rounded,
    label: 'Quran',
    widget: RecitationBrowserScreen(),
  ),
  _TabDef(
    icon: Icons.admin_panel_settings_rounded,
    label: 'Admin',
    widget: AdminDashboardScreen(),
  ),
];

// ── Shell ──────────────────────────────────────────────────────────────────────

/// The root scaffold that wraps all main-navigation screens.
/// Uses [IndexedStack] to preserve state across tab switches.
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
    // Fetch notifications silently on shell mount to populate the badge.
    Future.microtask(() => ref.read(notificationsProvider.notifier).load());
  }

  List<_TabDef> get _tabs {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated && auth.user.isAdmin) return _adminTabs;
    if (auth is AuthAuthenticated && auth.user.isTherapist) return _therapistTabs;
    return _userTabs;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final tabs = _tabs;
    // Clamp index — admin/user tab counts differ, avoid out-of-bounds on role change.
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: tabs.map((t) => t.widget).toList(),
          ),
          // Notification bell — positioned top-right, above all tab content.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: _NotificationBell(unreadCount: unreadCount),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _NoorBottomNav(
        tabs: tabs,
        currentIndex: safeIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Notification bell ──────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: unreadCount > 0
                  ? AppColors.brandTeal
                  : AppColors.textSecondary,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: _Badge(count: unreadCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE53E3E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _NoorBottomNav extends StatelessWidget {
  const _NoorBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabDef> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              tabs.length,
              (i) => _NavItem(
                icon: tabs[i].icon,
                label: tabs[i].label,
                isActive: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandTeal : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
