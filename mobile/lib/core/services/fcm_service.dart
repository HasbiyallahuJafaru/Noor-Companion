/// fcm_service.dart — Firebase Cloud Messaging setup for Noor Companion.
///
/// Handles three delivery contexts:
///   - Foreground:   app is open → show in-app banner via ScaffoldMessenger.
///   - Background:   app is backgrounded → system tray notification (FCM handles display).
///   - Terminated:   app was closed → system tray; on tap, [getInitialMessage] provides data.
///
/// ACTIVATION: Firebase is not yet initialised (pending `flutterfire configure`).
/// All methods guard on [Firebase.apps.isNotEmpty] before calling any Firebase API.
/// Once configured, remove the guard and uncomment the Firebase init in main.dart.
library;

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Activate post flutterfire configure

/// Top-level background message handler.
/// Must be a top-level function — cannot be a class method.
/// Registered via [FcmService.init].
///
/// FCM displays system notifications for background messages automatically.
/// This handler runs in an isolate — only use root-level globals here.
// @pragma('vm:entry-point')
// Future<void> _onBackgroundMessage(RemoteMessage message) async {
//   // Background processing — no UI access.
//   // The notification is shown by FCM automatically if notification: {} is set.
// }

/// Initialises FCM listeners and registers this device's token with the backend.
///
/// Call once from [NoorApp.build] after Firebase is initialised.
class FcmService {
  FcmService._();

  /// Initialises all FCM listeners.
  ///
  /// [ref] is used to read [notificationsProvider] for badge updates.
  /// [onTokenRefresh] is called whenever FCM rotates the device token so the
  /// backend can be updated.
  static Future<void> init({
    required WidgetRef ref,
    required Future<void> Function(String token) onTokenRefresh,
  }) async {
    // Guard: Firebase not yet configured — remove once flutterfire configure is run.
    // if (Firebase.apps.isEmpty) return;

    // final messaging = FirebaseMessaging.instance;

    // Request permission (iOS only — Android grants automatically).
    // await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // Register background handler (must be top-level function).
    // FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Get the initial FCM token and send it to the backend.
    // final token = await messaging.getToken();
    // if (token != null) await onTokenRefresh(token);

    // Listen for token refreshes.
    // messaging.onTokenRefresh.listen(onTokenRefresh);

    // Handle messages while the app is in the foreground.
    // FirebaseMessaging.onMessage.listen((message) {
    //   _handleForegroundMessage(message, ref);
    // });

    // Handle notification tap when app is in background (not terminated).
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   _handleNotificationTap(message, ref);
    // });

    // Handle notification tap when app was terminated.
    // final initial = await messaging.getInitialMessage();
    // if (initial != null) _handleNotificationTap(initial, ref);
  }

  /// Shows a custom in-app banner when a push arrives while the app is open.
  // static void _handleForegroundMessage(RemoteMessage message, WidgetRef ref) {
  //   ref.read(notificationsProvider.notifier).incrementUnreadCount();
  //   final title = message.notification?.title ?? '';
  //   final body  = message.notification?.body  ?? '';
  //   if (title.isEmpty) return;
  //   _showBanner(title: title, body: body);
  // }

  /// Navigates to the correct screen when a notification is tapped.
  // static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
  //   final type = message.data['type'] as String?;
  //   switch (type) {
  //     case 'session_incoming':
  //       // Navigate to call screen — sessionId in message.data
  //       break;
  //     case 'subscription_active':
  //     case 'streak_reminder':
  //       // Navigate to home
  //       break;
  //     default:
  //       break;
  //   }
  // }

  /// Displays a [SnackBar]-style banner at the top of the screen.
  static void showBanner({
    required BuildContext context,
    required String title,
    required String body,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        backgroundColor: const Color(0xFF0D7C6E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
