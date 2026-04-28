/**
 * Admin routes — restricted to role = admin.
 * Covers therapist approval queue and user management stubs.
 * Analytics, content management, and broadcast are added in Phase 8.
 */

'use strict';

const { Router } = require('express');
const Sentry = require('@sentry/node');
const { authenticate } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');
const { validate } = require('../middleware/validate');
const { rejectTherapistSchema } = require('../validators/therapists.validator');
const {
  listPendingTherapists,
  approveTherapist,
  rejectTherapist,
} = require('../services/therapists.service');

const router = Router();

router.use(authenticate, roleGuard('admin'));

/**
 * GET /api/v1/admin/therapists/pending
 * Returns all therapist profiles awaiting review, oldest first.
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
 * Sets the therapist status to active. Sends FCM push + email.
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
 * Sets the therapist status to rejected. Sends FCM push + email.
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

module.exports = router;
