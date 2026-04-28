/**
 * Content service — CRUD for platform-managed content (dhikr, duas, recitations).
 * Handles Redis caching and content progress recording.
 * Streak logic is delegated to streak.service.
 *
 * Cache strategy: lists are cached 24 hours per category+tag combination.
 * Cache is busted when admin creates or updates content (handled by admin service).
 */

'use strict';

const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');
const { updateStreak } = require('./streak.service');

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

module.exports = { listContent, recordProgress };
