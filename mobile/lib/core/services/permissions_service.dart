/// Centralised permission management for Noor Companion.
/// All runtime permission requests go through this service so there is a single
/// place to audit, extend, and handle permission rationale UI.
///
/// Call [requestAppPermissions] once on startup (after auth) to obtain the
/// permissions the app needs upfront. Individual features (calling, location)
/// also call their specific request method before use as a last-resort guard.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  const PermissionsService._();

  // ── Startup ────────────────────────────────────────────────────────────────

  /// Requests all permissions the app needs at launch.
  /// Failures are silent — individual features degrade gracefully when denied.
  ///
  /// Call this once after the user is authenticated and the home screen loads.
  static Future<void> requestAppPermissions() async {
    await Future.wait([
      requestNotifications(),
      requestLocation(),
    ]);
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  /// Requests push notification permission.
  /// On iOS this shows the system dialog via firebase_messaging.
  /// On Android 13+ this requests POST_NOTIFICATIONS via permission_handler.
  ///
  /// Returns true if permission was granted.
  static Future<bool> requestNotifications() async {
    // iOS / macOS — delegate to Firebase which handles the native dialog.
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final iosGranted = settings.authorizationStatus ==
        AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    // Android 13+ — runtime permission needed in addition to Firebase setup.
    final androidStatus = await Permission.notification.request();

    return iosGranted || androidStatus.isGranted;
  }

  // ── Location ───────────────────────────────────────────────────────────────

  /// Requests location permission for prayer times.
  /// Requests "when in use" only — background location is not needed.
  ///
  /// Returns true if permission was granted.
  static Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Returns true if location permission is currently granted.
  /// Use this before calling geolocator — avoids redundant permission dialogs.
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // ── Microphone ─────────────────────────────────────────────────────────────

  /// Requests microphone permission required for Agora voice calls.
  /// Must be called before initialising the Agora RTC engine.
  ///
  /// Returns true if permission was granted.
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Returns true if microphone permission is currently granted.
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
}
