/**
 * Therapist directory routes — public-facing (auth required, no role restriction).
 * POST /profile is restricted to role = therapist.
 */

'use strict';

const { Router } = require('express');
const Sentry = require('@sentry/node');
const { authenticate } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');
const { validate } = require('../middleware/validate');
const {
  listTherapistsSchema,
  upsertProfileSchema,
} = require('../validators/therapists.validator');
const {
  listTherapists,
  getTherapistById,
  upsertTherapistProfile,
} = require('../services/therapists.service');

const router = Router();

/**
 * GET /api/v1/therapists
 * Returns paginated active therapists. Optional filters: specialisation, language.
 * Auth: required
 */
router.get(
  '/',
  authenticate,
  validate(listTherapistsSchema, 'query'),
  async (req, res, next) => {
    try {
      const result = await listTherapists(req.query);
      return res.json({ success: true, data: result });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

/**
 * GET /api/v1/therapists/:therapistProfileId
 * Returns a single therapist's full profile.
 * Auth: required
 */
router.get('/:therapistProfileId', authenticate, async (req, res, next) => {
  try {
    const therapist = await getTherapistById(req.params.therapistProfileId);
    return res.json({ success: true, data: therapist });
  } catch (err) {
    Sentry.captureException(err);
    return next(err);
  }
});

/**
 * POST /api/v1/therapists/profile
 * Create or update the authenticated therapist's own profile.
 * Role: therapist only
 */
router.post(
  '/profile',
  authenticate,
  roleGuard('therapist'),
  validate(upsertProfileSchema, 'body'),
  async (req, res, next) => {
    try {
      const profile = await upsertTherapistProfile(req.user.id, req.body);
      return res.json({ success: true, data: profile });
    } catch (err) {
      Sentry.captureException(err);
      return next(err);
    }
  },
);

module.exports = router;
