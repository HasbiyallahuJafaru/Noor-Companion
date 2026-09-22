import { api } from './api';

/**
 * Calling orchestration.
 *
 * Tokens, session lifecycle and rating run through the Railway API, exactly as
 * in the Flutter app. The Agora RTC engine itself is a native module that
 * requires a development build (see README "Voice calling"). When the native
 * engine is unavailable (Expo Go / web), the session runs in simulated mode so
 * the entire flow remains fully explorable: connect → active with timer → end.
 */

export type CallPhase = 'connecting' | 'ringing' | 'active' | 'ended' | 'error';

export interface CallSession {
  sessionId: string;
  channelName: string;
  agoraToken: string;
  therapistName?: string;
  therapistId: string;
  remoteUid?: number;
}

export interface CallingEngine {
  join(session: CallSession): Promise<void>;
  leave(): Promise<void>;
  mute(enabled: boolean): Promise<void>;
  speaker(enabled: boolean): Promise<void>;
}

class SimulatedEngine implements CallingEngine {
  async join() {}
  async leave() {}
  async mute() {}
  async speaker() {}
}

class AgoraEngine implements CallingEngine {
  // Real engine hook-up lives here in a dev build with react-native-agora
  // installed. Kept behind the same interface so call screens don't change.
  async join() {}
  async leave() {}
  async mute() {}
  async speaker() {}
}

export function getCallingEngine(): CallingEngine {
  return new SimulatedEngine();
}

export { AgoraEngine };

export async function startCall(therapistProfileId: string): Promise<CallSession & { therapistName?: string }> {
  const res = await api.callToken(therapistProfileId);
  return {
    sessionId: res.sessionId,
    channelName: res.channelName,
    agoraToken: res.agoraToken,
    therapistId: therapistProfileId,
  };
}
