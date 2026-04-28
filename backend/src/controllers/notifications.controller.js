/**
 * notifications.controller.js — thin layer for the notifications endpoints.
 * All DB access is done directly here (no separate service needed for simple CRUD).
 * Business logic: list user's notifications, mark all as read.
 */

'use strict';

const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/notifications
 *
 * Returns the authenticated user's notifications newest-first.
 * Optional query: unreadOnly=true, page, limit.
 * Always returns the total unread count so the client can update the badge.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function listNotifications(req, res, next) {
  try {
    const { id: userId } = req.user;
    const unreadOnly = req.query.unreadOnly === 'true';
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
    const offset = (page - 1) * limit;

    const where = {
      userId,
      ...(unreadOnly ? { isRead: false } : {}),
    };

    const [notifications, unreadCount] = await prisma.$transaction([
      prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
        select: {
          id: true,
          type: true,
          title: true,
          body: true,
          isRead: true,
          data: true,
          createdAt: true,
        },
      }),
      prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    return res.json({
      success: true,
      data: { notifications, unreadCount },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/notifications/read-all
 *
 * Marks every unread notification for the authenticated user as read.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function markAllRead(req, res, next) {
  try {
    const { id: userId } = req.user;

    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return res.json({
      success: true,
      data: { message: 'All notifications marked as read.' },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { listNotifications, markAllRead };
