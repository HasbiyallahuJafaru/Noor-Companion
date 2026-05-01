/**
 * Calling service — manages the full call session lifecycle.
 * Handles initiation (token generation + therapist notification),
 * ending (duration recording), and post-call rating.
 *
 * All errors carry a code and statusCode so the route handler can
 * forward them to the global error handler unchanged.
 */

'use strict';

const { createId } = require('@paralleldrive/cuid2');
const { prisma } = require('../config/prisma');
const { generateRtcToken } = require('../utils/agora');
const { notificationService } = require('./notification.service');
const { getCallTimeoutQueue, CALL_TIMEOUT_JOB } = require('../workers/callTimeout.worker');

// ── Initiate call ─────────────────────────────────────────────────────────────

/**
 * Initiates a call from a paid user to an active therapist.
 * Verifies subscription, generates an Agora RTC token, creates a session
 * record, notifies the therapist via FCM, and queues a missed-call timeout.
 *
 * @param {string} userId - Calling user's Prisma ID (must be paid tier)
 * @param {string} therapistProfileId - Target therapist profile ID
 * @returns {Promise<{ sessionId, channelName, agoraToken, agoraAppId }>}
 * @throws {{ code: 'SUBSCRIPTION_REQUIRED', statusCode: 403 }}
 * @throws {{ code: 'NOT_FOUND', statusCode: 404 }}
 */
async function initiateCall(userId, therapistProfileId) {
  const caller = await _requirePaidUser(userId);
  const therapist = await _requireActiveTherapist(therapistProfileId);

  const channelName = `noor_${createId()}`;
  const agoraToken = generateRtcToken(channelName);

  const session = await prisma.callSession.create({
    data: { userId, therapistProfileId, agoraChannelName: channelName, status: 'initiated' },
    select: { id: true },
  });

  await _notifyTherapist(therapist, session.id, channelName, agoraToken, caller.firstName);
  await _scheduleTimeoutCheck(session.id);

  return {
    sessionId: session.id,
    channelName,
    agoraToken,
    agoraAppId: process.env.AGORA_APP_ID,
  };
}

// ── End call ──────────────────────────────────────────────────────────────────

/**
 * Ends a call session and records the duration.
 * Idempotent — returns existing data if session is already completed.
 * Called by either the user or the therapist.
 *
 * @param {string} sessionId
 * @returns {Promise<{ sessionId: string, durationSeconds: number }>}
 * @throws {{ code: 'NOT_FOUND', statusCode: 404 }}
 */
async function endCall(sessionId) {
  const session = await prisma.callSession.findUnique({
    where: { id: sessionId },
    select: { id: true, status: true, startedAt: true, durationSeconds: true },
  });

  if (!session) _throw('Session not found.', 'NOT_FOUND', 404);

  if (session.status === 'completed') {
    return { sessionId, durationSeconds: session.durationSeconds ?? 0 };
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

// ── Rate session ──────────────────────────────────────────────────────────────

/**
 * Submits a post-call rating for a completed session.
 * One rating per session — returns existing rating if already submitted.
 *
 * @param {string} userId - Must be the user who made the call
 * @param {string} sessionId
 * @param {number} rating - Integer 1–5
 * @param {string | undefined} comment - Optional feedback text
 * @returns {Promise<{ message: string }>}
 * @throws {{ code: 'NOT_FOUND', statusCode: 404 }}
 * @throws {{ code: 'FORBIDDEN', statusCode: 403 }}
 */
async function rateSession(userId, sessionId, rating, comment) {
  const session = await prisma.callSession.findUnique({
    where: { id: sessionId },
    select: { userId: true, therapistProfileId: true, status: true, rating: true },
  });

  if (!session) _throw('Session not found.', 'NOT_FOUND', 404);
  if (session.userId !== userId) _throw('Forbidden.', 'FORBIDDEN', 403);
  if (session.rating) return { message: 'Rating submitted.' };

  await prisma.sessionRating.create({
    data: { sessionId, userId, therapistProfileId: session.therapistProfileId, rating, comment },
  });

  return { message: 'Rating submitted.' };
}

// ── Mark session started ──────────────────────────────────────────────────────

/**
 * Marks the session as active (sets startedAt to now) when the therapist joins.
 * Called from the missed-call worker's pre-check — if already active, no-op.
 *
 * @param {string} sessionId
 * @returns {Promise<void>}
 */
async function markSessionStarted(sessionId) {
  await prisma.callSession.updateMany({
    where: { id: sessionId, status: 'initiated' },
    data: { status: 'active', startedAt: new Date() },
  });
}

// ── Private helpers ───────────────────────────────────────────────────────────

async function _requirePaidUser(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { subscriptionTier: true, firstName: true },
  });

  if (user?.subscriptionTier !== 'paid') {
    _throw('Calling requires a paid subscription.', 'SUBSCRIPTION_REQUIRED', 403);
  }

  return user;
}

async function _requireActiveTherapist(therapistProfileId) {
  const therapist = await prisma.therapistProfile.findUnique({
    where: { id: therapistProfileId, status: 'active' },
    include: { user: { select: { id: true, fcmToken: true, firstName: true } } },
  });

  if (!therapist) _throw('Therapist not found or unavailable.', 'NOT_FOUND', 404);

  return therapist;
}

async function _notifyTherapist(therapist, sessionId, channelName, agoraToken, callerName) {
  if (!therapist.user.fcmToken) return;

  try {
    await notificationService.sendDirectPush(therapist.user.fcmToken, {
      notification: { title: 'Incoming Call', body: `${callerName} is calling you` },
      data: {
        type: 'session_incoming',
        sessionId,
        channelName,
        agoraToken,
        agoraAppId: process.env.AGORA_APP_ID ?? '',
        callerName,
      },
    });
  } catch (err) {
    console.error('[calling] error:', err.message);
  }
}

async function _scheduleTimeoutCheck(sessionId) {
  try {
    const queue = getCallTimeoutQueue();
    await queue.add(CALL_TIMEOUT_JOB, { sessionId }, { delay: 60_000 });
  } catch (err) {
    console.error('[calling] error:', err.message);
  }
}

function _throw(message, code, statusCode) {
  const err = new Error(message);
  err.code = code;
  err.statusCode = statusCode;
  throw err;
}

// ── Therapist session history ─────────────────────────────────────────────────

/**
 * Returns paginated call sessions for the authenticated therapist.
 * Looks up the therapist profile by userId, then queries sessions.
 *
 * @param {string} userId - Therapist's Prisma User ID
 * @param {{ page: number, limit: number }} params
 * @returns {Promise<{ sessions: object[], pagination: object }>}
 */
async function getTherapistSessions(userId, { page = 1, limit = 20 } = {}) {
  const profile = await prisma.therapistProfile.findUnique({
    where: { userId },
    select: { id: true },
  });

  if (!profile) return { sessions: [], pagination: { page, limit, total: 0 } };

  const skip = (page - 1) * limit;

  const [sessions, total] = await Promise.all([
    prisma.callSession.findMany({
      where: { therapistProfileId: profile.id },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
      select: {
        id: true,
        status: true,
        durationSeconds: true,
        createdAt: true,
        endedAt: true,
        user: { select: { firstName: true, lastName: true, avatarUrl: true } },
        rating: { select: { rating: true, comment: true } },
      },
    }),
    prisma.callSession.count({ where: { therapistProfileId: profile.id } }),
  ]);

  return { sessions, pagination: { page, limit, total } };
}

module.exports = { initiateCall, endCall, rateSession, markSessionStarted, getTherapistSessions };
