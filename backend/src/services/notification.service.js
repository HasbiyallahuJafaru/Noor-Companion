/**
 * Notification service — sends FCM push notifications and persists
 * notification records for in-app display (Phase 7).
 *
 * sendDirectPush: fire a push to a known FCM token.
 * sendToUser: look up a user's FCM token then fire the push.
 *
 * Both methods are fire-and-forget safe — errors are captured in Sentry
 * and never propagate to the caller.
 */

'use strict';

const Sentry = require('@sentry/node');
const { admin } = require('../config/firebase');
const { prisma } = require('../config/prisma');

/**
 * Sends an FCM push directly to a known device token.
 * Accepts any valid FCM message payload.
 *
 * @param {string} fcmToken - Target device FCM registration token
 * @param {{ notification?: { title: string, body: string }, data?: Record<string, string> }} payload
 * @returns {Promise<void>}
 */
async function sendDirectPush(fcmToken, payload) {
  if (!fcmToken) return;

  try {
    await admin.messaging().send({
      token: fcmToken,
      ...payload,
      android: { priority: 'high' },
      apns: { payload: { aps: { 'content-available': 1 } } },
    });
  } catch (err) {
    Sentry.captureException(err, { extra: { fcmToken: '[redacted]' } });
  }
}

/**
 * Looks up a user's FCM token then sends a push notification.
 * Silently skips if the user has no FCM token registered.
 *
 * @param {string} userId - Prisma user ID
 * @param {{ type: string, title: string, body: string }} options
 * @returns {Promise<void>}
 */
async function sendToUser(userId, { type, title, body }) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (!user?.fcmToken) return;

    await sendDirectPush(user.fcmToken, {
      notification: { title, body },
      data: { type },
    });
  } catch (err) {
    Sentry.captureException(err, { extra: { userId } });
  }
}

const notificationService = { sendDirectPush, sendToUser };

module.exports = { notificationService };
