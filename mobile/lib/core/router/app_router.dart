/// Application router for Noor Companion.
/// Uses GoRouter with role-based redirect guards.
/// Auth state drives redirects — unauthenticated users land on splash/login,
/// authenticated users land on the app shell.
library;

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/intervention/presentation/screens/intervention_dua_screen.dart';
import '../../features/intervention/presentation/screens/intervention_breathing_screen.dart';
import '../../features/intervention/presentation/screens/intervention_task_screen.dart';
import '../../features/intervention/presentation/screens/intervention_affirm_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_addiction_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_stage_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_therapist_screen.dart';
import '../../features/therapists/presentation/screens/therapist_detail_screen.dart';
import '../shell/app_shell.dart';

/// Named route paths — use these constants instead of raw strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
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
  static const String milestone = '/milestone/:badge';
}

/// Builds the GoRouter instance.
/// Auth state integration added in Phase 1 — currently routes to home directly.
GoRouter buildAppRouter({bool isAuthenticated = false}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
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
      // Intervention flow — 4 sequential full-screen routes
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
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Call ${state.pathParameters['sessionId']}'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.milestone,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Milestone ${state.pathParameters['badge']}'),
          ),
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
