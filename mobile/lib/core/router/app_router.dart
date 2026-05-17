/// Application router for Noor Companion.
/// Uses GoRouter with auth-state-driven redirect guards.
/// All sub-screens use slide-fade transitions; auth screens use fade-only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/intervention/presentation/screens/intervention_affirm_screen.dart';
import '../../features/intervention/presentation/screens/intervention_breathing_screen.dart';
import '../../features/intervention/presentation/screens/intervention_dua_screen.dart';
import '../../features/intervention/presentation/screens/intervention_task_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_addiction_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_stage_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_therapist_screen.dart';
import '../../features/home/presentation/screens/return_screen.dart';
import '../../features/progress/presentation/screens/milestone_screen.dart';
import '../../features/calling/presentation/screens/call_screen.dart';
import '../../features/therapists/presentation/screens/therapist_detail_screen.dart';
import '../../features/dhikr/presentation/screens/dhikr_detail_screen.dart';
import '../../features/duas/presentation/screens/dua_library_screen.dart';
import '../../features/duas/presentation/screens/dua_detail_screen.dart';
import '../../features/quran/presentation/screens/recitation_browser_screen.dart';
import '../../features/quran/presentation/screens/surah_screen.dart';
import '../../features/subscription/presentation/screens/upgrade_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_therapists_screen.dart';
import '../../features/admin/presentation/screens/admin_content_screen.dart';
import '../../features/admin/presentation/screens/admin_content_add_screen.dart';
import '../../features/admin/presentation/screens/admin_broadcast_screen.dart';
import '../../features/therapist_dashboard/presentation/screens/therapist_dashboard_screen.dart';
import '../../features/therapist_dashboard/presentation/screens/therapist_session_history_screen.dart';
import '../../features/therapist_dashboard/presentation/screens/incoming_call_screen.dart';
import '../shell/app_shell.dart';
import 'page_transitions.dart';

/// Named route path constants — always use these, never raw strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String onboardingAddiction = '/onboarding/addiction';
  static const String onboardingStage = '/onboarding/stage';
  static const String onboardingTherapist = '/onboarding/therapist';
  static const String intervention = '/intervention/dua';
  static const String interventionBreathing = '/intervention/breathing';
  static const String interventionTask = '/intervention/task';
  static const String interventionAffirm = '/intervention/affirm';
  static const String therapistDetail = '/therapists/:id';
  static const String call = '/call/:sessionId';
  static const String milestone = '/milestone/:days';
  static const String returnScreen = '/return';
  static const String dhikrDetail = '/dhikr/:id';
  static const String duas = '/duas';
  static const String duaDetail = '/duas/:id';
  static const String quran = '/quran';
  static const String surah = '/quran/:surahNumber';
  static const String subscriptionUpgrade = '/subscription/upgrade';
  static const String notifications = '/notifications';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminTherapists = '/admin/therapists';
  static const String adminContent = '/admin/content';
  static const String adminContentAdd = '/admin/content/add';
  static const String adminBroadcast = '/admin/broadcast';
  static const String therapistDashboard = '/therapist-dashboard';
  static const String therapistSessions = '/therapist-dashboard/sessions';
  static const String incomingCall = '/incoming-call';
}

/// Unprotected routes — accessible without a session.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
};

/// Builds the GoRouter instance with a Riverpod [ref] for auth state.
GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final current = ref.read(authProvider);
      final path = state.matchedLocation;

      if (current is AuthLoading) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (current is AuthAuthenticated) {
        if (_publicRoutes.contains(path)) return AppRoutes.home;
        if (path.startsWith('/admin') && !current.user.isAdmin) {
          return AppRoutes.home;
        }
        if (path.startsWith('/therapist-dashboard') &&
            !current.user.isTherapist) {
          return AppRoutes.home;
        }
        return null;
      }

      if (path == AppRoutes.splash) return AppRoutes.login;
      if (_publicRoutes.contains(path)) return null;
      return AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, s) => fadePage(state: s, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, s) => fadePage(state: s, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, s) => fadePage(state: s, child: const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, s) =>
            NoTransitionPage(key: s.pageKey, child: const AppShell()),
      ),
      GoRoute(
        path: AppRoutes.onboardingAddiction,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const OnboardingAddictionScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingStage,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const OnboardingStageScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingTherapist,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const OnboardingTherapistScreen()),
      ),
      GoRoute(
        path: AppRoutes.intervention,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const InterventionDuaScreen()),
      ),
      GoRoute(
        path: AppRoutes.interventionBreathing,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const InterventionBreathingScreen()),
      ),
      GoRoute(
        path: AppRoutes.interventionTask,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const InterventionTaskScreen()),
      ),
      GoRoute(
        path: AppRoutes.interventionAffirm,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const InterventionAffirmScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistDetail,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: TherapistDetailScreen(
            therapistId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.call,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return slideFadePage(
            state: state,
            child: CallScreen(
              sessionId: state.pathParameters['sessionId']!,
              channelName: extra['channelName'] ?? '',
              agoraToken: extra['agoraToken'] ?? '',
              therapistName: extra['therapistName'] ?? 'Therapist',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.milestone,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: MilestoneScreen(
            days: int.tryParse(state.pathParameters['days'] ?? '') ?? 7,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.returnScreen,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const ReturnScreen()),
      ),
      GoRoute(
        path: AppRoutes.dhikrDetail,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: DhikrDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.duas,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const DuaLibraryScreen()),
      ),
      GoRoute(
        path: AppRoutes.duaDetail,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: DuaDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.quran,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const RecitationBrowserScreen()),
      ),
      GoRoute(
        path: AppRoutes.surah,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: SurahScreen(
            surahNumber:
                int.tryParse(state.pathParameters['surahNumber'] ?? '') ?? 1,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscriptionUpgrade,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const UpgradeScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const AdminUsersScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetail,
        pageBuilder: (_, state) => slideFadePage(
          state: state,
          child: AdminUserDetailScreen(userId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminTherapists,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const AdminTherapistsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminContent,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const AdminContentScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminContentAdd,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const AdminContentAddScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminBroadcast,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const AdminBroadcastScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistDashboard,
        pageBuilder: (_, s) =>
            slideFadePage(state: s, child: const TherapistDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.therapistSessions,
        pageBuilder: (_, s) => slideFadePage(
          state: s,
          child: const TherapistSessionHistoryScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.incomingCall,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return slideFadePage(
            state: state,
            child: IncomingCallScreen(
              sessionId: extra['sessionId'] ?? '',
              channelName: extra['channelName'] ?? '',
              agoraToken: extra['agoraToken'] ?? '',
              callerName: extra['callerName'] ?? 'User',
            ),
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

/// Bridges Riverpod auth state changes into a [Listenable] for GoRouter.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(WidgetRef ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}
