/**
 * Authentication middleware.
 * Verifies the Supabase access token from the Authorization header.
 * Attaches the full app user record to req.user on success.
 * Returns 401 on missing, invalid, or expired token.
 */

'use strict';

const { supabase } = require('../config/supabase');
const { prisma } = require('../config/prisma');

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

    // Upsert the app user from Supabase metadata on every first-time login.
    // This handles the case where Supabase Auth created the account but
    // the backend users table has no matching row yet.
    const meta = supabaseUser.user_metadata ?? {};
    const appUser = await prisma.user.upsert({
      where: { supabaseId: supabaseUser.id },
      create: {
        supabaseId: supabaseUser.id,
        firstName: meta.first_name ?? 'User',
        lastName: meta.last_name ?? '',
        role: meta.role ?? 'user',
      },
      update: {},
      select: {
        id: true,
        supabaseId: true,
        firstName: true,
        lastName: true,
        role: true,
        subscriptionTier: true,
        isActive: true,
        fcmToken: true,
      },
    });

    if (!appUser.isActive) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Account suspended.' },
      });
    }

    req.user = appUser;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { authenticate };
