/// Persistent app shell with floating glass bottom navigation bar.
/// Role-based tabs: user, therapist, admin — all with Profile tab.
/// Tab switches crossfade. Nav items scale-bounce on tap.
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
import '../theme/app_theme.dart';
import '../widgets/noor_icons.dart';

/// Icon builder signature shared with [NoorIcons].
typedef _IconBuilder = Widget Function({double size, Color color});

class _TabDef {
  const _TabDef({required this.icon, required this.label, required this.widget});
  final _IconBuilder icon;
  final String label;
  final Widget widget;
}

final _userTabs = [
  _TabDef(icon: NoorIcons.home, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: NoorIcons.sparkles, label: 'Dhikr', widget: DhikrLibraryScreen()),
  _TabDef(icon: NoorIcons.bookOpen, label: 'Quran', widget: RecitationBrowserScreen()),
  _TabDef(icon: NoorIcons.heart, label: 'Therapists', widget: TherapistsScreen()),
  _TabDef(icon: NoorIcons.user, label: 'Profile', widget: ProfileScreen()),
];

final _therapistTabs = [
  _TabDef(icon: NoorIcons.home, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: NoorIcons.sparkles, label: 'Dhikr', widget: DhikrLibraryScreen()),
  _TabDef(icon: NoorIcons.chart, label: 'Dashboard', widget: TherapistDashboardScreen()),
  _TabDef(icon: NoorIcons.user, label: 'Profile', widget: ProfileScreen()),
];

final _adminTabs = [
  _TabDef(icon: NoorIcons.home, label: 'Home', widget: HomeScreen()),
  _TabDef(icon: NoorIcons.shield, label: 'Admin', widget: AdminDashboardScreen()),
  _TabDef(icon: NoorIcons.bookOpen, label: 'Quran', widget: RecitationBrowserScreen()),
  _TabDef(icon: NoorIcons.user, label: 'Profile', widget: ProfileScreen()),
];

// ── Shell ──────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  /// Drives the crossfade when switching tabs.
  double _contentOpacity = 1.0;

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

  void _onTabTap(int i) {
    if (i == _currentIndex) return;
    // Flash content opacity to 0 then back on the next frame — quick crossfade.
    setState(() {
      _contentOpacity = 0.0;
      _currentIndex = i;
    });
    Future.microtask(() {
      if (mounted) setState(() => _contentOpacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final tabs = _tabs;
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          // ── Tab content with crossfade ──────────────────────────────────
          AnimatedOpacity(
            opacity: _contentOpacity,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: IndexedStack(
              index: safeIndex,
              children: tabs.map((t) => t.widget).toList(),
            ),
          ),
          // ── Notification bell ───────────────────────────────────────────
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
          // ── Floating glass nav ──────────────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _FloatingNav(
              tabs: tabs,
              currentIndex: safeIndex,
              onTap: _onTabTap,
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
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24171930),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              return Expanded(
                child: _NavItem(
                  icon: tabs[i].icon,
                  label: tabs[i].label,
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Nav item with scale-bounce feedback ───────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final _IconBuilder icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _ctrl.forward();
  void _handleTapUp(_) => _ctrl.reverse().then((_) => widget.onTap());
  void _handleTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active tab: filled ink circle with a white glyph — the
            // signature motif of the reference design.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isActive ? AppColors.ink : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: widget.isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x33171930),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.icon(
                  size: widget.isActive ? 20 : 22,
                  color: widget.isActive ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color:
                    widget.isActive ? AppColors.ink : AppColors.textMuted,
                fontWeight:
                    widget.isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            NoorIcons.bell(
              size: 20,
              color: unreadCount > 0
                  ? AppColors.brandTeal
                  : AppColors.textSecondary,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
