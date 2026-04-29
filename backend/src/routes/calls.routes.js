/**
 * Calling routes — /api/v1/calls
 * All routes require authentication.
 * POST /token: paid users only, rate-limited to 5/min.
 * POST /:sessionId/end: either party ends the session.
 * POST /:sessionId/rate: user rates a completed session.
 */

'use strict';

const { Router } = require('express');
const Sentry = require('@sentry/node');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { callRateLimiter } = require('../middleware/rateLimiter');
const { initiateCall, endCall, rateSession, getTherapistSessions } = require('../services/calling.service');
const { initiateCallSchema, rateCallSchema } = require('../validators/calls.validator');
const { prisma } = require('../config/prisma');

const router = Router();

router.use(authenticate);

// ── POST /api/v1/calls/token ──────────────────────────────────────────────────

router.post('/token', callRateLimiter, validate(initiateCallSchema), async (req, res, next) => {
  try {
    const data = await initiateCall(req.user.id, req.body.therapistProfileId);
    res.json({ success: true, data });
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({
      success: false,
      error: { code: err.code, message: err.message },
    });
    Sentry.captureException(err);
    next(err);
  }
});

// ── POST /api/v1/calls/:sessionId/end ────────────────────────────────────────

router.post('/:sessionId/end', async (req, res, next) => {
  try {
    const data = await endCall(req.params.sessionId);
    res.json({ success: true, data });
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({
      success: false,
      error: { code: err.code, message: err.message },
    });
    Sentry.captureException(err);
    next(err);
  }
});

// ── POST /api/v1/calls/:sessionId/rate ───────────────────────────────────────

router.post('/:sessionId/rate', validate(rateCallSchema), async (req, res, next) => {
  try {
    const data = await rateSession(
      req.user.id,
      req.params.sessionId,
      req.body.rating,
      req.body.comment,
    );
    res.json({ success: true, data });
  } catch (err) {
    if (err.statusCode) return res.status(err.statusCode).json({
      success: false,
      error: { code: err.code, message: err.message },
    });
    Sentry.captureException(err);
    next(err);
  }
});

// ── POST /api/v1/calls/:sessionId/renew-token ────────────────────────────────

router.post('/:sessionId/renew-token', async (req, res, next) => {
  try {
    const session = await prisma.callSession.findUnique({
      where: { id: req.params.sessionId },
      select: { agoraChannelName: true, status: true, userId: true, therapistProfile: { select: { userId: true } } },
    });

    if (!session) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Session not found.' },
      });
    }

    // Only the user or therapist in the session can renew the token.
    const isParticipant =
      session.userId === req.user.id ||
      session.therapistProfile?.userId === req.user.id;

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'Not a participant in this session.' },
      });
    }

    if (session.status === 'completed' || session.status === 'missed') {
      return res.status(400).json({
        success: false,
        error: { code: 'SESSION_ENDED', message: 'Session is no longer active.' },
      });
    }

    const { generateRtcToken } = require('../utils/agora');
    const agoraToken = generateRtcToken(session.agoraChannelName);
    res.json({ success: true, data: { agoraToken } });
  } catch (err) {
    Sentry.captureException(err);
    next(err);
  }
});

// ── GET /api/v1/calls/my-sessions ────────────────────────────────────────────

router.get('/my-sessions', async (req, res, next) => {
  try {
    if (req.user.role !== 'therapist') {
      return res.status(403).json({
        success: false,
        error: { code: 'FORBIDDEN', message: 'Therapist role required.' },
      });
    }
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const data = await getTherapistSessions(req.user.id, { page, limit });
    res.json({ success: true, data });
  } catch (err) {
    Sentry.captureException(err);
    next(err);
  }
});

module.exports = router;
