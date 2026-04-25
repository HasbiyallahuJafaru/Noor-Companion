/// Firebase Cloud Messaging handler for Noor Companion.
/// Registers foreground and background message listeners.
/// Routes notification taps to the correct screen based on type field.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Notification type constants matching backend FCM payloads.
abstract final class NotificationType {
  static const morningReminder = 'morning_reminder';
  static const eveningReflection = 'evening_reflection';
  static const taskReminder = 'task_reminder';
  static const therapistAvailable = 'therapist_available';
  static const milestoneUnlocked = 'milestone_unlocked';
}

/// Background/terminated message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this fires.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Wires all FCM listeners and requests permission.
/// Call once from main.dart after Firebase.initializeApp().
Future<void> initNotifications(GoRouter router) async {
  final messaging = FirebaseMessaging.instance;

  await _requestPermission(messaging);
  await _printToken(messaging);

  // Foreground messages — show a local notification or in-app banner.
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    // Phase 2: replace with flutter_local_notifications banner.
  });

  // Tap on notification while app is in background (not terminated).
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _route(router, message);
  });

  // Tap on notification that launched app from terminated state.
  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    // Defer until the router is ready.
    Future.microtask(() => _route(router, initial));
  }
}

Future<void> _requestPermission(FirebaseMessaging messaging) async {
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
}

Future<void> _printToken(FirebaseMessaging messaging) async {
  final token = await messaging.getToken();
  debugPrint('[FCM] Device token: $token');
  // Phase 2: POST token to /api/v1/users/me/fcm-token.
}

/// Routes a tapped notification to the appropriate screen.
void _route(GoRouter router, RemoteMessage message) {
  final type = message.data['type'] as String?;
  final id = message.data['id'] as String?;

  switch (type) {
    case NotificationType.morningReminder:
    case NotificationType.eveningReflection:
    case NotificationType.taskReminder:
      router.go('/home');

    case NotificationType.therapistAvailable:
      if (id != null) {
        router.push('/therapists/$id');
      } else {
        router.go('/home');
      }

    case NotificationType.milestoneUnlocked:
      if (id != null) {
        router.push('/milestone/$id');
      } else {
        router.go('/home');
      }

    default:
      router.go('/home');
  }
}
