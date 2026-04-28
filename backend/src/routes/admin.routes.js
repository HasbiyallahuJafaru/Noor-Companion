/**
 * Admin routes — all restricted to role = admin.
 * Covers analytics, user management, therapist approval,
 * content management, and broadcast notifications.
 */

'use strict';

const { Router } = require('express');
const Sentry = require('@sentry/node');
const { authenticate } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');
const { validate } = require('../middleware/validate');
const { rejectTherapistSchema } = require('../validators/therapists.validator');
const {
  listUsersSchema,
  updateUserSchema,
  createContentSchema,
  updateContentSchema,
  listContentSchema,
  broadcastSchema,
} = require('../validators/admin.validator');
const {
  listPendingTherapists,
  approveTherapist,
  rejectTherapist,
} = require('../services/therapists.service');
const {
  getAnalytics,
  listUsers,
  getUserById,
  updateUser,
  listAllContent,
  createContent,
  updateContent,
  broadcastNotification,
} = require('../services/admin.service');

const router = Router();

router.use(authenticate, roleGuard('admin'));

// ── Analytics ─────────────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/analytics
 * Returns platform-wide summary stats for the dashboard.
 */
router.get('/analytics', async (req, res, next) => {
  try {
    const data = await getAnalytics();
    return res.json({ success: true, data });
  } catch (err) {
    Sentry.captureException(err);
    return next(err);
  }
});

// ── User management ───────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/users
 * Paginated user list with optional role/tier/search filters.
 */
router.get(
  '/users',
  validate(listUsersSchema, 'query'),
  async (req, res, next) => {
    try {
      const data = await listUsers(req.query);
      return res.json({ success: true, data });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

/**
 * GET /api/v1/admin/users/:userId
 * Full profile for a single user.
 */
router.get('/users/:userId', async (req, res, next) => {
  try {
    const user = await getUserById(req.params.userId);
    return res.json({ success: true, data: user });
  } catch (err) {
    Sentry.captureException(err);
    return next(err);
  }
});

/**
 * PATCH /api/v1/admin/users/:userId
 * Suspend a user (isActive = false) or manually set subscription tier.
 */
router.patch(
  '/users/:userId',
  validate(updateUserSchema, 'body'),
  async (req, res, next) => {
    try {
      const updated = await updateUser(req.params.userId, req.body, req.user.id);
      return res.json({ success: true, data: updated });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

// ── Therapist approval ────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/therapists/pending
 * Returns therapists awaiting approval, oldest first.
 */
router.get('/therapists/pending', async (req, res, next) => {
  try {
    const pending = await listPendingTherapists();
    return res.json({ success: true, data: pending });
  } catch (err) {
    Sentry.captureException(err);
    return next(err);
  }
});

/**
 * POST /api/v1/admin/therapists/:therapistProfileId/approve
 * Activates the therapist profile. Sends FCM push + email.
 */
router.post(
  '/therapists/:therapistProfileId/approve',
  async (req, res, next) => {
    try {
      await approveTherapist(req.params.therapistProfileId, req.user.id);
      return res.json({ success: true, data: { message: 'Therapist approved.' } });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

/**
 * POST /api/v1/admin/therapists/:therapistProfileId/reject
 * Rejects the profile with a reason. Sends FCM push + email.
 */
router.post(
  '/therapists/:therapistProfileId/reject',
  validate(rejectTherapistSchema, 'body'),
  async (req, res, next) => {
    try {
      await rejectTherapist(req.params.therapistProfileId, req.body.reason);
      return res.json({ success: true, data: { message: 'Therapist rejected.' } });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

// ── Content management ────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/content
 * Returns all content items (active + inactive), optionally filtered by category.
 */
router.get(
  '/content',
  validate(listContentSchema, 'query'),
  async (req, res, next) => {
    try {
      const data = await listAllContent(req.query);
      return res.json({ success: true, data });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

/**
 * POST /api/v1/admin/content
 * Creates a new content item and busts the Redis cache.
 */
router.post(
  '/content',
  validate(createContentSchema, 'body'),
  async (req, res, next) => {
    try {
      const item = await createContent(req.body);
      return res.status(201).json({ success: true, data: item });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

/**
 * PATCH /api/v1/admin/content/:contentId
 * Toggles isActive or updates fields. Busts the Redis cache.
 */
router.patch(
  '/content/:contentId',
  validate(updateContentSchema, 'body'),
  async (req, res, next) => {
    try {
      const item = await updateContent(req.params.contentId, req.body);
      return res.json({ success: true, data: item });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

// ── Broadcast notifications ───────────────────────────────────────────────────

/**
 * POST /api/v1/admin/notifications/broadcast
 * Sends an FCM push to all users of a given role and persists records.
 */
router.post(
  '/notifications/broadcast',
  validate(broadcastSchema, 'body'),
  async (req, res, next) => {
    try {
      const { title, body, targetRole } = req.body;
      const result = await broadcastNotification(title, body, targetRole);
      return res.json({ success: true, data: result });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

module.exports = router;
