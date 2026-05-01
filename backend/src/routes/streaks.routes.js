/**
 * Streaks routes — exposes the authenticated user's streak data.
 * All routes require a valid Supabase session token.
 */

'use strict';

const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { getUserStreak } = require('../services/streak.service');

const router = Router();

/**
 * GET /api/v1/streaks/me
 *
 * Returns the current user's streak summary.
 * Creates a zero-state response for users who have never engaged.
 *
 * Auth: required
 * Response: { success: true, data: { currentStreak, longestStreak, totalDays, lastEngagedAt } }
 */
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const streak = await getUserStreak(req.user.id);
    return res.json({ success: true, data: streak });
  } catch (err) {

    return next(err);
  }
});

module.exports = router;
