/**
 * Authentication middleware.
 * Verifies the Supabase access token from the Authorization header.
 * Attaches the full app user record to req.user on success.
 * Returns 401 on missing, invalid, or expired token.
 *
 * Performance: tokens are verified locally with SUPABASE_JWT_SECRET when
 * available (no network roundtrip per request), and the app user row is
 * cached in memory for 30s. Falls back to Supabase's remote getUser for
 * any token the local check rejects, so correctness never depends on the
 * secret being configured.
 */

'use strict';

const jwt = require('jsonwebtoken');
const { supabase } = require('../config/supabase');
const { prisma } = require('../config/prisma');

// supabaseId -> { user, expiresAt }. 30s staleness window: role changes or
// suspensions take up to 30s to reach already-logged-in sessions.
const USER_CACHE_TTL_MS = 30_000;
const _userCache = new Map();

const USER_SELECT = {
  id: true,
  supabaseId: true,
  firstName: true,
  lastName: true,
  role: true,
  subscriptionTier: true,
  isActive: true,
  fcmToken: true,
};

/**
 * Verifies a Supabase HS256 access token locally. Returns the payload or null.
 * @param {string} token
 * @returns {object|null}
 */
function _verifyLocally(token) {
  const secret = process.env.SUPABASE_JWT_SECRET;
  if (!secret) return null;
  try {
    return jwt.verify(token, secret, { algorithms: ['HS256'] });
  } catch {
    return null;
  }
}

/**
 * Loads the app user for a Supabase user id, creating the row on first login.
 * Caches the result for USER_CACHE_TTL_MS.
 *
 * @param {string} supabaseId
 * @param {{ first_name?: string, last_name?: string, role?: string }} meta
 * @returns {Promise<object>}
 */
async function _loadAppUser(supabaseId, meta) {
  const cached = _userCache.get(supabaseId);
  if (cached && cached.expiresAt > Date.now()) return cached.user;
  if (cached) _userCache.delete(supabaseId);

  const appUser = await prisma.user.upsert({
    where: { supabaseId },
    create: {
      supabaseId,
      firstName: meta.first_name ?? 'User',
      lastName: meta.last_name ?? '',
      // user_metadata is client-controlled at signup — only 'therapist' may
      // be self-selected. 'admin' is granted out-of-band via scripts/make-admin.js.
      role: meta.role === 'therapist' ? 'therapist' : 'user',
    },
    update: {},
    select: USER_SELECT,
  });

  _userCache.set(supabaseId, { user: appUser, expiresAt: Date.now() + USER_CACHE_TTL_MS });
  return appUser;
}

/**
 * Verifies Bearer token via Supabase and loads the matching app user.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'No token provided.' },
      });
    }

    const token = authHeader.split(' ')[1];

    let supabaseId;
    let email;
    let meta;

    const payload = _verifyLocally(token);
    if (payload?.sub) {
      supabaseId = payload.sub;
      email = payload.email ?? '';
      meta = payload.user_metadata ?? {};
    } else {
      const {
        data: { user: supabaseUser },
        error,
      } = await supabase.auth.getUser(token);

      if (error || !supabaseUser) {
        return res.status(401).json({
          success: false,
          error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token.' },
        });
      }

      supabaseId = supabaseUser.id;
      email = supabaseUser.email;
      meta = supabaseUser.user_metadata ?? {};
    }

    const appUser = await _loadAppUser(supabaseId, meta);

    if (!appUser.isActive) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Account suspended.' },
      });
    }

    req.user = { ...appUser, email };
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { authenticate };
