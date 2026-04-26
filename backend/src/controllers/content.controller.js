/**
 * Content controller — thin layer between routes and content service.
 * Handles dhikr, duas, recitations, and content progress.
 * Contains no business logic — delegates entirely to content service.
 */

'use strict';

const contentService = require('../services/content.service');

/**
 * GET /api/v1/content/dhikr
 * Returns all active dhikr items, optionally filtered by tag.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function listDhikr(req, res, next) {
  try {
    const { tag } = req.query;
    const items = await contentService.listContent('dhikr', tag);
    return res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/content/duas
 * Returns all active dua items, optionally filtered by tag.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function listDuas(req, res, next) {
  try {
    const { tag } = req.query;
    const items = await contentService.listContent('dua', tag);
    return res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/content/recitations
 * Returns all active recitation items, optionally filtered by tag.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function listRecitations(req, res, next) {
  try {
    const { tag } = req.query;
    const items = await contentService.listContent('recitation', tag);
    return res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/content/:contentId/progress
 * Records that the authenticated user engaged with a content item.
 * Idempotent per user per content item. Updates streak.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function recordProgress(req, res, next) {
  try {
    const { contentId } = req.params;
    const result = await contentService.recordProgress(req.user.id, contentId);
    return res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

module.exports = { listDhikr, listDuas, listRecitations, recordProgress };
