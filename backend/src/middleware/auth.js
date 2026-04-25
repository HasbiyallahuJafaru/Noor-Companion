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

    const appUser = await prisma.user.findUnique({
      where: { supabaseId: supabaseUser.id },
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

    if (!appUser || !appUser.isActive) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Account not found or suspended.' },
      });
    }

    req.user = appUser;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { authenticate };
