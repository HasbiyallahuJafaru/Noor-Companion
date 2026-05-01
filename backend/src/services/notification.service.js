/**
 * notification.service.js — FCM push + in-app notification persistence.
 *
 * Every notification is both pushed to FCM and stored in the Notification
 * table so the Flutter app can display a persistent in-app feed.
 *
 * sendDirectPush: fire a raw FCM push to a device token (no DB record).
 * sendToUser:     persist + FCM push to a single user by their app User.id.
 * broadcastToRole: persist + FCM push to all active users with a given role.
 */

'use strict';

const { admin } = require('../config/firebase');
const { prisma } = require('../config/prisma');

// FCM sends are batched at this size to stay within the API limit.
const FCM_BATCH_SIZE = 500;

// ── Direct push ───────────────────────────────────────────────────────────────

/**
 * Sends a raw FCM push to a known device token. No database record is created.
 * Safe to call without awaiting — errors are captured in Sentry, never re-thrown.
 *
 * @param {string} fcmToken  - Target device FCM registration token
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
    console.error('[notification] sendDirectPush error:', err.message);
  }
}

// ── Send + persist to one user ────────────────────────────────────────────────

/**
 * Saves a Notification record to the database and sends an FCM push to the user.
 * Silently skips the push if the user has no FCM token — the DB record is always saved.
 *
 * @param {string} userId - App User.id (CUID)
 * @param {{ type: string, title: string, body: string, data?: object }} options
 * @returns {Promise<void>}
 */
async function sendToUser(userId, { type, title, body, data }) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (!user) return;

    await prisma.notification.create({
      data: { userId, type, title, body, data: data ?? undefined },
    });

    if (user.fcmToken) {
      await sendDirectPush(user.fcmToken, {
        notification: { title, body },
        data: { type, ...(data ? { payload: JSON.stringify(data) } : {}) },
      });
    }
  } catch (err) {
    console.error('[notification] sendToUser error:', err.message);
  }
}

// ── Broadcast to role ─────────────────────────────────────────────────────────

/**
 * Sends a notification to all active users with the given role.
 * Persists one DB record per user and sends FCM in batches of 500.
 *
 * @param {string} role - 'user' | 'therapist' | 'admin'
 * @param {{ type: string, title: string, body: string, data?: object }} options
 * @returns {Promise<void>}
 */
async function broadcastToRole(role, { type, title, body, data }) {
  try {
    const users = await prisma.user.findMany({
      where: { role, isActive: true },
      select: { id: true, fcmToken: true },
    });

    if (users.length === 0) return;

    await prisma.notification.createMany({
      data: users.map((u) => ({
        userId: u.id,
        type,
        title,
        body,
        data: data ?? undefined,
      })),
    });

    const tokens = users
      .map((u) => u.fcmToken)
      .filter(Boolean);

    for (let i = 0; i < tokens.length; i += FCM_BATCH_SIZE) {
      const batch = tokens.slice(i, i + FCM_BATCH_SIZE);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data: { type },
          android: { priority: 'high' },
          apns: { payload: { aps: { 'content-available': 1 } } },
        });
      } catch (err) {
        console.error('[notification] broadcastToRole batch error:', err.message);
      }
    }
  } catch (err) {
    console.error('[notification] broadcastToRole error:', err.message);
  }
}

const notificationService = { sendDirectPush, sendToUser, broadcastToRole };

module.exports = { notificationService };
