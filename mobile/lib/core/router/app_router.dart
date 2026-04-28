/// Application router for Noor Companion.
/// Uses GoRouter with auth-state-driven redirect guards.
/// Unauthenticated users are sent to /login.
/// Authenticated users are sent to /home (or onboarding on first launch).
/// Role guards prevent users from accessing admin/therapist routes.
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
import '../shell/app_shell.dart';

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
}

/// Unprotected routes — accessible without a session.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
};

/// Builds the GoRouter instance with a Riverpod [ref] for auth state.
/// Pass the ref from [NoorApp] so the router refreshes on auth changes.
GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    // Refresh when auth state changes so redirects fire.
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final current = ref.read(authProvider);
      final path = state.matchedLocation;

      // While resolving auth, stay on splash.
      if (current is AuthLoading) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Authenticated user — redirect away from public routes.
      if (current is AuthAuthenticated) {
        if (_publicRoutes.contains(path)) return AppRoutes.home;
        return null;
      }

      // Unauthenticated — redirect to login unless on a public route.
      if (_publicRoutes.contains(path)) return null;
      return AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const AppShell(),
      ),
      GoRoute(
        path: AppRoutes.onboardingAddiction,
        builder: (_, _) => const OnboardingAddictionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingStage,
        builder: (_, _) => const OnboardingStageScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingTherapist,
        builder: (_, _) => const OnboardingTherapistScreen(),
      ),
      GoRoute(
        path: AppRoutes.intervention,
        builder: (_, _) => const InterventionDuaScreen(),
      ),
      GoRoute(
        path: AppRoutes.interventionBreathing,
        builder: (_, _) => const InterventionBreathingScreen(),
      ),
      GoRoute(
        path: AppRoutes.interventionTask,
        builder: (_, _) => const InterventionTaskScreen(),
      ),
      GoRoute(
        path: AppRoutes.interventionAffirm,
        builder: (_, _) => const InterventionAffirmScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistDetail,
        builder: (_, state) => TherapistDetailScreen(
          therapistId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.call,
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return CallScreen(
            sessionId: state.pathParameters['sessionId']!,
            channelName: extra['channelName'] ?? '',
            agoraToken: extra['agoraToken'] ?? '',
            therapistName: extra['therapistName'] ?? 'Therapist',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.milestone,
        builder: (_, state) => MilestoneScreen(
          days: int.tryParse(state.pathParameters['days'] ?? '') ?? 7,
        ),
      ),
      GoRoute(
        path: AppRoutes.returnScreen,
        builder: (_, _) => const ReturnScreen(),
      ),
      GoRoute(
        path: AppRoutes.dhikrDetail,
        builder: (_, state) =>
            DhikrDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.duas,
        builder: (_, _) => const DuaLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.duaDetail,
        builder: (_, state) =>
            DuaDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.quran,
        builder: (_, _) => const RecitationBrowserScreen(),
      ),
      GoRoute(
        path: AppRoutes.surah,
        builder: (_, state) => SurahScreen(
          surahNumber:
              int.tryParse(state.pathParameters['surahNumber'] ?? '') ?? 1,
        ),
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
