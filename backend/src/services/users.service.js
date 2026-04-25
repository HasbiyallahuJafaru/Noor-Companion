/**
 * Users service — business logic for user profile operations.
 * Called by users.controller. Never called directly from routes.
 */

'use strict';

const { prisma } = require('../config/prisma');

/**
 * Returns the authenticated user's profile and streak.
 *
 * @param {string} userId - The app User.id (not the Supabase UUID)
 * @returns {Promise<object>} User with nested streak
 */
async function getMe(userId) {
  return prisma.user.findUniqueOrThrow({
    where: { id: userId },
    select: {
      id: true,
      supabaseId: true,
      firstName: true,
      lastName: true,
      role: true,
      subscriptionTier: true,
      avatarUrl: true,
      isActive: true,
      streak: {
        select: {
          currentStreak: true,
          longestStreak: true,
          totalDays: true,
          lastEngagedAt: true,
        },
      },
    },
  });
}

/**
 * Updates editable profile fields for the given user.
 * Only firstName, lastName, and avatarUrl are editable.
 *
 * @param {string} userId
 * @param {{ firstName?: string, lastName?: string, avatarUrl?: string | null }} updates
 * @returns {Promise<void>}
 */
async function updateProfile(userId, updates) {
  await prisma.user.update({
    where: { id: userId },
    data: updates,
  });
}

/**
 * Stores or updates the FCM device token for push notifications.
 *
 * @param {string} userId
 * @param {string} fcmToken
 * @returns {Promise<void>}
 */
async function saveFcmToken(userId, fcmToken) {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

module.exports = { getMe, updateProfile, saveFcmToken };
