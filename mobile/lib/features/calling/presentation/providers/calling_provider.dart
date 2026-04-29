/// Riverpod provider for the Agora calling feature.
/// CallingNotifier manages the full call lifecycle:
/// joining the channel, handling remote party events, ending, and clean-up.
/// Auto-disposed when the call screen leaves the widget tree.
library;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/calling_state.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final callingProvider =
    NotifierProvider.autoDispose<CallingNotifier, CallingState>(CallingNotifier.new);

// ── Notifier ──────────────────────────────────────────────────────────────────

class CallingNotifier extends Notifier<CallingState> {
  RtcEngine? _engine;

  @override
  CallingState build() {
    ref.onDispose(() {
      _engine?.leaveChannel();
      _engine?.release();
    });
    return const CallingIdle();
  }

  // ── Join ───────────────────────────────────────────────────────────────────

  /// Initialises Agora and joins the call channel.
  /// Requests microphone permission first — fails fast if denied.
  /// Registers all event handlers BEFORE calling joinChannel per Agora docs.
  ///
  /// @param token - Agora RTC token from the backend (1-hour expiry)
  /// @param channelName - Unique channel name for this session
  /// @param sessionId - Database session ID used to end/renew the session
  Future<void> joinCall({
    required String token,
    required String channelName,
    required String sessionId,
  }) async {
    state = const CallingConnecting();

    try {
      // Microphone permission must be granted before the engine is initialised.
      // Agora will silently fail to capture audio if the permission is missing.
      final hasMic = await PermissionsService.requestMicrophone();
      if (!hasMic) {
        state = const CallingError(
          'Microphone permission is required for voice calls.',
        );
        return;
      }

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handler BEFORE joining — ensures no events are missed.
      // Audio is enabled by default in channelProfileCommunication — no
      // explicit enableAudio() call needed (calling it would reset audio state).
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          state = CallingActive(sessionId: sessionId);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          final current = state;
          if (current is CallingActive) {
            state = current.copyWith(remoteUid: remoteUid);
          }
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          endCall(sessionId);
        },
        onError: (ErrorCodeType err, String msg) {
          Sentry.captureMessage(
            'Agora error: ${err.name} — $msg',
            level: SentryLevel.error,
          );
          state = CallingError(msg);
        },
        // Fired 30 seconds before the 1-hour Agora token expires.
        // Requests a fresh token from the backend and renews without
        // interrupting the call.
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          _renewToken(sessionId);
        },
      ));

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
      state = CallingError(e.toString());
    }
  }

  // ── Token renewal ──────────────────────────────────────────────────────────

  /// Requests a fresh Agora token from the backend and calls renewToken on the
  /// engine. Called automatically when onTokenPrivilegeWillExpire fires.
  /// Failure is captured in Sentry but does not end the call — Agora gives a
  /// 30-second window so the user has time to retry or finish naturally.
  ///
  /// @param sessionId - Active session ID for the backend token endpoint
  Future<void> _renewToken(String sessionId) async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/calls/$sessionId/renew-token');
      final newToken = res.data['data']['agoraToken'] as String;
      await _engine?.renewToken(newToken);
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }
  }

  // ── End call ───────────────────────────────────────────────────────────────

  /// Ends the call, leaves the Agora channel, and notifies the backend.
  /// Safe to call multiple times — guards against double-ending.
  ///
  /// @param sessionId - Database session ID
  Future<void> endCall(String sessionId) async {
    if (state is CallingEnded) return;

    int? durationSeconds;

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;

      final dio = ref.read(apiClientProvider);
      final res = await dio.post('/calls/$sessionId/end');
      durationSeconds = res.data['data']['durationSeconds'] as int?;
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }

    state = CallingEnded(sessionId: sessionId, durationSeconds: durationSeconds);
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  /// Stops or resumes publishing the local audio stream.
  /// Does not affect audio capture — only remote users' reception changes.
  ///
  /// @param muted - true to mute, false to unmute
  Future<void> toggleMute({required bool muted}) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }
  }

  // ── Rating ─────────────────────────────────────────────────────────────────

  /// Submits a 1–5 star rating for the completed session.
  ///
  /// @param sessionId
  /// @param rating - Integer 1–5
  /// @param comment - Optional feedback text
  Future<void> submitRating(String sessionId, int rating, {String? comment}) async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/calls/$sessionId/rate', data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } on DioException catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }
  }
}
