/**
 * Rate limiter configurations.
 * Uses express-rate-limit. Tighter limits on auth-adjacent routes.
 */

'use strict';

const rateLimit = require('express-rate-limit');

/** General API rate limit — 200 requests per minute per IP. */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: { code: 'RATE_LIMITED', message: 'Too many requests. Try again shortly.' },
  },
});

/** Tighter limit for FCM token updates and other write-once operations. */
const writeLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: { code: 'RATE_LIMITED', message: 'Too many requests. Try again shortly.' },
  },
});

/** Strict limit for call initiation — 5 calls per minute per IP. */
const callRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: { code: 'RATE_LIMITED', message: 'Too many call requests. Try again shortly.' },
  },
});

module.exports = { apiLimiter, writeLimiter, callRateLimiter };
