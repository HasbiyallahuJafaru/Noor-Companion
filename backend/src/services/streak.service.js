/**
 * Streak service — reads, calculates, and persists user engagement streaks.
 * Also provides the query used by the BullMQ streak risk worker.
 *
 * updateStreak is the single source of truth for streak logic.
 * It is called by content.service after recording progress.
 */

'use strict';

const { prisma } = require('../config/prisma');

/**
 * Returns the streak record for a user. Creates a zero-state record if
 * the user has never engaged with content.
 *
 * @param {string} userId - Internal user ID (cuid)
 * @returns {Promise<{currentStreak: number, longestStreak: number, totalDays: number, lastEngagedAt: Date|null}>}
 */
async function getUserStreak(userId) {
  const streak = await prisma.streak.findUnique({ where: { userId } });

  if (!streak) {
    return { currentStreak: 0, longestStreak: 0, totalDays: 0, lastEngagedAt: null };
  }

  return {
    currentStreak: streak.currentStreak,
    longestStreak: streak.longestStreak,
    totalDays: streak.totalDays,
    lastEngagedAt: streak.lastEngagedAt,
  };
}

/**
 * Calculates and persists the streak for a user based on their last engagement.
 * Creates the streak record if it does not exist yet.
 * Safe to call multiple times on the same day — idempotent for today.
 *
 * Logic:
 * - Same day as lastEngagedAt → no change
 * - Consecutive day → currentStreak + 1
 * - Gap of 2+ days → reset to 1
 * - longestStreak updated whenever currentStreak exceeds it
 *
 * @param {string} userId
 * @returns {Promise<import('@prisma/client').Streak>}
 */
async function updateStreak(userId) {
  const now = new Date();
  const todayUTC = _toUTCDay(now);

  const existing = await prisma.streak.findUnique({ where: { userId } });

  if (!existing) {
    return prisma.streak.create({
      data: {
        userId,
        currentStreak: 1,
        longestStreak: 1,
        totalDays: 1,
        lastEngagedAt: todayUTC,
      },
    });
  }

  const lastDate = existing.lastEngagedAt ? _toUTCDay(existing.lastEngagedAt) : null;

  if (lastDate && lastDate.getTime() === todayUTC.getTime()) {
    return existing;
  }

  const yesterdayUTC = new Date(todayUTC.getTime() - 86_400_000);
  const isConsecutive = lastDate && lastDate.getTime() === yesterdayUTC.getTime();

  const newCurrent = isConsecutive ? existing.currentStreak + 1 : 1;
  const newLongest = Math.max(existing.longestStreak, newCurrent);

  return prisma.streak.update({
    where: { userId },
    data: {
      currentStreak: newCurrent,
      longestStreak: newLongest,
      totalDays: { increment: 1 },
      lastEngagedAt: todayUTC,
    },
  });
}

/**
 * Returns all users whose streak is at risk:
 * streak > 0, has not engaged today, and lastEngagedAt was yesterday or earlier.
 * Used by the daily streak risk BullMQ worker to target FCM pushes.
 *
 * @returns {Promise<Array<{userId: string, currentStreak: number, fcmToken: string|null}>>}
 */
async function findStreakRiskUsers() {
  const now = new Date();
  const todayUTC = _toUTCDay(now);

  const atRisk = await prisma.streak.findMany({
    where: {
      currentStreak: { gt: 0 },
      lastEngagedAt: { lt: todayUTC },
    },
    select: {
      currentStreak: true,
      user: {
        select: { id: true, fcmToken: true, isActive: true },
      },
    },
  });

  return atRisk
    .filter((s) => s.user.isActive && s.user.fcmToken)
    .map((s) => ({
      userId: s.user.id,
      currentStreak: s.currentStreak,
      fcmToken: s.user.fcmToken,
    }));
}

/**
 * Normalises a Date to midnight UTC on the same calendar day.
 * Used for day-boundary comparisons throughout this module.
 *
 * @param {Date} date
 * @returns {Date}
 */
function _toUTCDay(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

module.exports = { getUserStreak, updateStreak, findStreakRiskUsers };
