# CALLING.md — Noor Companion
# Agora WebRTC calling — token generation, call lifecycle, Flutter integration.
# Read this before writing any calling-related code.

## How Agora Works in This Project

1. Backend generates a short-lived Agora RTC token for a specific channel
2. Channel name is unique per session: noor_<cuid>
3. Both user and therapist join the same channel using the token
4. Agora's servers handle the actual media relay
5. On call end, session duration is recorded in our database

Free tier: 10,000 minutes/month. After that: $0.0099/min.
Agora docs: https://docs.agora.io/en/
Flutter SDK: https://pub.dev/packages/agora_rtc_engine (check latest version)

---

## Backend: Token Generation

```javascript
/**
 * Agora utility — generates RTC tokens for call sessions.
 * Tokens are short-lived (1 hour) and channel-specific.
 * Never store tokens in the database — generate on demand.
 *
 * Requires: npm install agora-token (verify current package name first)
 * Agora token docs: https://docs.agora.io/en/video-calling/get-started/authentication-workflow
 */

const { RtcTokenBuilder, RtcRole } = require('agora-token');

// Token validity: 1 hour from generation time
const TOKEN_EXPIRY_SECONDS = 3600;

/**
 * Generates an Agora RTC token for a specific channel.
 * Both caller and recipient use uid = 0 (Agora auto-assigns unique IDs).
 *
 * @param {string} channelName - Unique channel name (format: noor_<cuid>)
 * @returns {string} Signed Agora RTC token
 */
function generateRtcToken(channelName) {
  const currentTime = Math.floor(Date.now() / 1000);
  const expiryTime = currentTime + TOKEN_EXPIRY_SECONDS;

  return RtcTokenBuilder.buildTokenWithUid(
    process.env.AGORA_APP_ID,
    process.env.AGORA_APP_CERTIFICATE,
    channelName,
    0,             // uid 0 = Agora auto-assigns
    RtcRole.PUBLISHER, // Both parties can send and receive
    expiryTime,
    expiryTime
  );
}

module.exports = { generateRtcToken };
```

---

## Backend: Calling Service

```javascript
/**
 * Calling service — manages call session lifecycle.
 * Handles initiation, token generation, therapist notification,
 * session recording, and missed-call detection.
 */

const { createId } = require('@paralleldrive/cuid2');
const { prisma } = require('../config/prisma');
const { generateRtcToken } = require('../utils/agora');
const { notificationService } = require('./notification.service');
const { callTimeoutQueue } = require('../jobs/queues');
const Sentry = require('@sentry/node');

/**
 * Initiates a call between a paid user and an active therapist.
 * Checks subscription tier, generates Agora token, creates session record,
 * and notifies the therapist via FCM.
 *
 * @param {string} userId - ID of the calling user (must be paid tier)
 * @param {string} therapistProfileId - ID of the therapist to call
 * @returns {Promise<{ sessionId, channelName, agoraToken, agoraAppId }>}
 * @throws {Error} SUBSCRIPTION_REQUIRED — user is not on paid tier
 * @throws {Error} NOT_FOUND — therapist not found or not active
 */
async function initiateCall(userId, therapistProfileId) {
  // Verify subscription tier — paid only
  const caller = await prisma.user.findUnique({
    where: { id: userId },
    select: { subscriptionTier: true, firstName: true },
  });

  if (caller.subscriptionTier !== 'paid') {
    const error = new Error('Calling requires a paid subscription.');
    error.code = 'SUBSCRIPTION_REQUIRED';
    error.statusCode = 403;
    throw error;
  }

  // Verify therapist exists and is active
  const therapist = await prisma.therapistProfile.findUnique({
    where: { id: therapistProfileId, status: 'active' },
    include: {
      user: { select: { id: true, fcmToken: true, firstName: true } },
    },
  });

  if (!therapist) {
    const error = new Error('Therapist not found or unavailable.');
    error.code = 'NOT_FOUND';
    error.statusCode = 404;
    throw error;
  }

  // Generate unique channel name — one channel per session, never reused
  const channelName = `noor_${createId()}`;

  // Generate Agora RTC token
  const agoraToken = generateRtcToken(channelName);

  // Create session record in database
  const session = await prisma.callSession.create({
    data: {
      userId,
      therapistProfileId,
      agoraChannelName: channelName,
      status: 'initiated',
    },
    select: { id: true },
  });

  // Send incoming call push to therapist
  // The FCM data payload includes everything the therapist's app needs to join
  if (therapist.user.fcmToken) {
    try {
      await notificationService.sendDirectPush(therapist.user.fcmToken, {
        notification: {
          title: 'Incoming Call',
          body: `${caller.firstName} is calling you`,
        },
        data: {
          type: 'session_incoming',
          sessionId: session.id,
          channelName,
          agoraToken,
          agoraAppId: process.env.AGORA_APP_ID,
          callerName: caller.firstName,
        },
      });
    } catch (error) {
      // Log but don't fail — therapist might still join if app is open
      Sentry.captureException(error, { extra: { sessionId: session.id } });
    }
  }

  // Schedule missed-call check — if session is still 'initiated' after 60s,
  // mark it as missed and notify the caller
  await callTimeoutQueue.add(
    'check-missed',
    { sessionId: session.id },
    { delay: 60_000 }
  );

  return {
    sessionId: session.id,
    channelName,
    agoraToken,
    agoraAppId: process.env.AGORA_APP_ID,
  };
}

/**
 * Ends a call session and records the duration.
 * Idempotent — safe to call multiple times (processes only once).
 * Called by either the user or the therapist.
 *
 * @param {string} sessionId
 * @returns {Promise<{ sessionId, durationSeconds }>}
 */
async function endCall(sessionId) {
  const session = await prisma.callSession.findUnique({
    where: { id: sessionId },
    select: { id: true, status: true, startedAt: true },
  });

  if (!session) {
    const error = new Error('Session not found.');
    error.code = 'NOT_FOUND';
    error.statusCode = 404;
    throw error;
  }

  // Already ended — return existing data without re-processing
  if (session.status === 'completed') {
    const existing = await prisma.callSession.findUnique({
      where: { id: sessionId },
      select: { durationSeconds: true },
    });
    return { sessionId, durationSeconds: existing.durationSeconds };
  }

  const endedAt = new Date();
  const durationSeconds = session.startedAt
    ? Math.floor((endedAt.getTime() - session.startedAt.getTime()) / 1000)
    : 0;

  await prisma.callSession.update({
    where: { id: sessionId },
    data: { status: 'completed', endedAt, durationSeconds },
  });

  return { sessionId, durationSeconds };
}

module.exports = { initiateCall, endCall };
```

---

## Missed Call BullMQ Worker

```javascript
/**
 * Worker: check-missed-call
 * Fires 60 seconds after a call is initiated.
 * If the session is still 'initiated', the therapist didn't answer.
 * Marks as missed and notifies the caller.
 */
async function processMissedCallCheck(job) {
  const { sessionId } = job.data;

  const session = await prisma.callSession.findUnique({
    where: { id: sessionId },
    select: { id: true, status: true, userId: true },
  });

  // Session was picked up — nothing to do
  if (!session || session.status !== 'initiated') return;

  await prisma.callSession.update({
    where: { id: sessionId },
    data: { status: 'missed' },
  });

  await notificationService.sendToUser(session.userId, {
    type: 'general',
    title: 'Therapist Unavailable',
    body: 'The therapist was not available right now. Please try again later.',
  });
}
```

---

## Flutter: Calling Feature

```dart
/// Calling provider — manages Agora engine and call state.
/// Scoped to the call screen lifetime. Engine is released on dispose.
class CallingNotifier extends StateNotifier<CallingState> {
  final ApiClient _api;
  RtcEngine? _engine;

  CallingNotifier(this._api) : super(const CallingState.idle());

  /// Initialises Agora and joins the call channel.
  /// Called immediately when the call screen mounts.
  ///
  /// @param token - Agora RTC token from the backend
  /// @param channelName - Unique channel name for this session
  /// @param sessionId - Database session ID — needed to end the session
  Future<void> joinCall({
    required String token,
    required String channelName,
    required String sessionId,
  }) async {
    state = const CallingState.connecting();

    try {
      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          state = CallingState.active(sessionId: sessionId);
        },
        onUserJoined: (_, remoteUid, __) {
          // Other party joined — update UI to show remote video
          if (state is CallingStateActive) {
            state = (state as CallingStateActive).copyWith(remoteUid: remoteUid);
          }
        },
        onUserOffline: (_, __, ___) {
          // Other party left — end the call
          endCall(sessionId);
        },
        onError: (code, message) {
          state = CallingState.error(message);
        },
      ));

      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

    } catch (e) {
      state = CallingState.error(e.toString());
    }
  }

  /// Ends the call, leaves the Agora channel, and notifies the backend.
  /// Always call this — from the end button, from onUserOffline, and on dispose.
  Future<void> endCall(String sessionId) async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;

      await _api.post('/calls/$sessionId/end');
    } catch (e) {
      Sentry.captureException(e);
    } finally {
      state = const CallingState.ended();
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}
```

---

## Agora Android Setup (android/app/build.gradle)

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Agora requires minimum API 21
    }
}
```

## Agora iOS Setup (ios/Runner/Info.plist)

```xml
<!-- Required for microphone access -->
<key>NSMicrophoneUsageDescription</key>
<string>Noor Companion needs microphone access for therapist calls.</string>

<!-- Required for camera access -->
<key>NSCameraUsageDescription</key>
<string>Noor Companion needs camera access for therapist video calls.</string>
```

---

## Security Notes

- Agora tokens are generated per-session and expire after 1 hour
- Channel names are CUIDs — not guessable
- The backend verifies paid subscription BEFORE generating any token
- Tokens are never stored in the database
- If a user's subscription is cancelled, they cannot generate new call tokens
