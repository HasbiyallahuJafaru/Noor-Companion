/**
 * Content service — CRUD for platform-managed content (dhikr, duas, recitations).
 * Handles Redis caching, content progress recording, and streak updates.
 *
 * Cache strategy: lists are cached 24 hours per category+tag combination.
 * Cache is busted when admin creates or updates content (handled by admin service).
 */

'use strict';

const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');

const CONTENT_CACHE_TTL = 86400; // 24 hours

/**
 * Builds the Redis cache key for a content list query.
 *
 * @param {string} category - 'dhikr' | 'dua' | 'recitation'
 * @param {string|undefined} tag - Optional tag filter
 * @returns {string}
 */
function buildContentCacheKey(category, tag) {
  return tag ? `content:${category}:tag:${tag}` : `content:${category}:all`;
}

/**
 * Returns cached content list or fetches from DB and caches.
 *
 * @param {string} key
 * @param {Function} fetchFn
 * @returns {Promise<object[]>}
 */
async function cacheOrFetch(key, fetchFn) {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);
  const fresh = await fetchFn();
  await redis.setex(key, CONTENT_CACHE_TTL, JSON.stringify(fresh));
  return fresh;
}

/**
 * Returns all active content items for a given category.
 * Optionally filtered by tag. Results cached 24 hours.
 *
 * @param {'dhikr'|'dua'|'recitation'} category
 * @param {string|undefined} tag
 * @returns {Promise<object[]>}
 */
async function listContent(category, tag) {
  const cacheKey = buildContentCacheKey(category, tag);

  return cacheOrFetch(cacheKey, async () => {
    const where = {
      category,
      isActive: true,
      ...(tag && { tags: { has: tag } }),
    };

    return prisma.content.findMany({
      where,
      select: {
        id: true,
        title: true,
        arabicText: true,
        transliteration: true,
        translation: true,
        audioUrl: true,
        tags: true,
        sortOrder: true,
      },
      orderBy: { sortOrder: 'asc' },
    });
  });
}

/**
 * Records user engagement with a content item. Idempotent per user per item.
 * Uses upsert — duplicate calls on the same day do not create duplicate rows.
 * Returns updated streak data.
 *
 * @param {string} userId - Our internal user ID (cuid)
 * @param {string} contentId
 * @returns {Promise<{ message: string, streak: { currentStreak: number, longestStreak: number } }>}
 */
async function recordProgress(userId, contentId) {
  const content = await prisma.content.findUnique({
    where: { id: contentId },
    select: { id: true, isActive: true },
  });

  if (!content || !content.isActive) {
    const err = new Error('Content item not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  await prisma.contentProgress.upsert({
    where: { userId_contentId: { userId, contentId } },
    create: { userId, contentId },
    update: { engagedAt: new Date() },
  });

  const streak = await updateStreak(userId);

  return {
    message: 'Progress recorded.',
    streak: {
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
    },
  };
}

/**
 * Calculates and persists the streak for a user based on last engagement.
 * Creates the streak record if it does not exist.
 *
 * @param {string} userId
 * @returns {Promise<import('@prisma/client').Streak>}
 */
async function updateStreak(userId) {
  const now = new Date();
  const todayUTC = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

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

  const lastDate = existing.lastEngagedAt
    ? new Date(Date.UTC(
        existing.lastEngagedAt.getUTCFullYear(),
        existing.lastEngagedAt.getUTCMonth(),
        existing.lastEngagedAt.getUTCDate(),
      ))
    : null;

  // Already engaged today — no change needed
  if (lastDate && lastDate.getTime() === todayUTC.getTime()) {
    return existing;
  }

  const yesterdayUTC = new Date(todayUTC.getTime() - 86400000);
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

module.exports = { listContent, recordProgress };
