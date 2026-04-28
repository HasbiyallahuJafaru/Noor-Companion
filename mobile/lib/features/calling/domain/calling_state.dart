/// Sealed class hierarchy representing every stage of a call session.
/// Used by CallingNotifier to drive the call screen UI.
library;

/// All possible states of an active call.
sealed class CallingState {
  const CallingState();
}

/// Initial state — no call in progress.
class CallingIdle extends CallingState {
  const CallingIdle();
}

/// Awaiting Agora channel connection after joinChannel() called.
class CallingConnecting extends CallingState {
  const CallingConnecting();
}

/// Both parties are connected and the call is active.
class CallingActive extends CallingState {
  const CallingActive({
    required this.sessionId,
    this.remoteUid,
  });

  final String sessionId;
  final int? remoteUid;

  CallingActive copyWith({String? sessionId, int? remoteUid}) => CallingActive(
        sessionId: sessionId ?? this.sessionId,
        remoteUid: remoteUid ?? this.remoteUid,
      );
}

/// Call has ended — may carry the session duration.
class CallingEnded extends CallingState {
  const CallingEnded({this.sessionId, this.durationSeconds});

  final String? sessionId;
  final int? durationSeconds;
}

/// An unrecoverable Agora or network error occurred.
class CallingError extends CallingState {
  const CallingError(this.message);

  final String message;
}
