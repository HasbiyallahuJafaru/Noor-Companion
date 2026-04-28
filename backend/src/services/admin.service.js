/**
 * Admin service — platform analytics, user management, content CRUD, and broadcast.
 * All functions are admin-only; role enforcement happens in admin.routes.js.
 * Content mutations bust the Redis cache so users see changes immediately.
 */

'use strict';

const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');
const { broadcastToRole } = require('./notification.service');

// ── Analytics ─────────────────────────────────────────────────────────────────

/**
 * Returns platform-wide summary statistics for the admin dashboard.
 *
 * @returns {Promise<object>} Dashboard analytics snapshot.
 */
async function getAnalytics() {
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const [
    totalUsers,
    activeToday,
    paidSubscribers,
    totalTherapists,
    pendingTherapists,
    callSessionsThisMonth,
  ] = await Promise.all([
    prisma.user.count({ where: { role: 'user' } }),
    prisma.user.count({
      where: {
        role: 'user',
        streak: { lastEngagedAt: { gte: startOfDay } },
      },
    }),
    prisma.user.count({ where: { subscriptionTier: 'paid' } }),
    prisma.therapistProfile.count({ where: { status: 'active' } }),
    prisma.therapistProfile.count({ where: { status: 'pending' } }),
    prisma.callSession.count({
      where: { createdAt: { gte: startOfMonth } },
    }),
  ]);

  return {
    totalUsers,
    activeToday,
    paidSubscribers,
    totalTherapists,
    pendingTherapists,
    callSessionsThisMonth,
  };
}

// ── User management ───────────────────────────────────────────────────────────

/**
 * Returns a paginated, filterable list of all platform users.
 *
 * @param {object} params
 * @param {string|undefined} params.role
 * @param {string|undefined} params.subscriptionTier
 * @param {string|undefined} params.search  - Matches first/last name prefix.
 * @param {number} params.page
 * @param {number} params.limit
 * @returns {Promise<{ users: object[], pagination: object }>}
 */
async function listUsers({ role, subscriptionTier, search, page, limit }) {
  const where = {
    ...(role && { role }),
    ...(subscriptionTier && { subscriptionTier }),
    ...(search && {
      OR: [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ],
    }),
  };

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      select: {
        id: true,
        firstName: true,
        lastName: true,
        role: true,
        subscriptionTier: true,
        isActive: true,
        createdAt: true,
        streak: { select: { lastEngagedAt: true, currentStreak: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.user.count({ where }),
  ]);

  return { users, pagination: { page, limit, total } };
}

/**
 * Returns the full profile for a single user.
 *
 * @param {string} userId - Internal cuid.
 * @returns {Promise<object>}
 */
async function getUserById(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      supabaseId: true,
      firstName: true,
      lastName: true,
      role: true,
      subscriptionTier: true,
      isActive: true,
      createdAt: true,
      streak: true,
    },
  });

  if (!user) {
    const err = new Error('User not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  return user;
}

/**
 * Updates a user's isActive or subscriptionTier.
 * Admin cannot change their own active status (prevents self-lockout).
 *
 * @param {string} userId
 * @param {object} updates - { isActive?, subscriptionTier? }
 * @param {string} adminId - The admin performing the update.
 * @returns {Promise<object>}
 */
async function updateUser(userId, updates, adminId) {
  if (userId === adminId && updates.isActive === false) {
    const err = new Error('Cannot suspend your own account.');
    err.statusCode = 400;
    err.code = 'VALIDATION_ERROR';
    throw err;
  }

  return prisma.user.update({
    where: { id: userId },
    data: updates,
    select: { id: true, isActive: true, subscriptionTier: true },
  });
}

// ── Content management ────────────────────────────────────────────────────────

/**
 * Returns all content items (active and inactive) for admin review.
 *
 * @param {'dhikr'|'dua'|'recitation'|undefined} category - Optional filter.
 * @param {number} page
 * @param {number} limit
 * @returns {Promise<{ items: object[], pagination: object }>}
 */
async function listAllContent({ category, page, limit }) {
  const where = category ? { category } : {};

  const [items, total] = await Promise.all([
    prisma.content.findMany({
      where,
      select: {
        id: true,
        title: true,
        category: true,
        tags: true,
        isActive: true,
        sortOrder: true,
        createdAt: true,
      },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.content.count({ where }),
  ]);

  return { items, pagination: { page, limit, total } };
}

/**
 * Creates a new content item and busts the relevant Redis cache.
 *
 * @param {object} data - Validated content fields.
 * @returns {Promise<object>} The created content item.
 */
async function createContent(data) {
  const item = await prisma.content.create({
    data,
    select: { id: true, title: true, category: true, isActive: true },
  });

  await _bustContentCache(data.category);
  return item;
}

/**
 * Updates a content item (toggle isActive, edit fields) and busts cache.
 *
 * @param {string} contentId
 * @param {object} updates
 * @returns {Promise<object>}
 */
async function updateContent(contentId, updates) {
  const existing = await prisma.content.findUnique({
    where: { id: contentId },
    select: { category: true },
  });

  if (!existing) {
    const err = new Error('Content item not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  const item = await prisma.content.update({
    where: { id: contentId },
    data: updates,
    select: { id: true, title: true, category: true, isActive: true },
  });

  await _bustContentCache(existing.category);
  return item;
}

/**
 * Deletes all Redis cache keys for a given content category.
 * Tags cannot be predicted, so we use pattern deletion.
 *
 * @param {string} category
 */
async function _bustContentCache(category) {
  const keys = await redis.keys(`content:${category}:*`);
  if (keys.length > 0) await redis.del(...keys);
}

// ── Broadcast ─────────────────────────────────────────────────────────────────

/**
 * Sends a push notification and persists a DB record for all users of a role.
 *
 * @param {string} title
 * @param {string} body
 * @param {'user'|'therapist'|'admin'} targetRole
 * @returns {Promise<{ sent: number }>}
 */
async function broadcastNotification(title, body, targetRole) {
  const count = await broadcastToRole(targetRole, { title, body, type: 'general' });
  return { sent: count };
}

module.exports = {
  getAnalytics,
  listUsers,
  getUserById,
  updateUser,
  listAllContent,
  createContent,
  updateContent,
  broadcastNotification,
};
