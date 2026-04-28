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

  /// Initialises Agora and joins the call channel.
  /// Call this immediately when the call screen mounts.
  ///
  /// @param token - Agora RTC token from the backend
  /// @param channelName - Unique channel name for this session
  /// @param sessionId - Database session ID used to end the session
  Future<void> joinCall({
    required String token,
    required String channelName,
    required String sessionId,
  }) async {
    state = const CallingConnecting();

    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          state = CallingActive(sessionId: sessionId);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          final current = state;
          if (current is CallingActive) {
            state = current.copyWith(remoteUid: remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          endCall(sessionId);
        },
        onError: (code, message) {
          state = CallingError(message);
        },
      ));

      await _engine!.enableAudio();

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

  /// Toggles the local microphone mute state.
  ///
  /// @param muted - true to mute, false to unmute
  Future<void> toggleMute({required bool muted}) async {
    try {
      await _engine?.muteLocalAudioStream(muted);
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }
  }

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
