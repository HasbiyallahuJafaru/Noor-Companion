/**
 * subscribe_token.controller.js — handles POST /api/v1/users/me/subscribe-token.
 * Separated from payments.controller.js because this route lives on /users.
 * Requires Supabase auth (user must be logged in to initiate payment).
 */

'use strict';

const paymentsService = require('../services/payments.service');

/**
 * POST /api/v1/users/me/subscribe-token
 *
 * Generates a short-lived signed token and a redirect URL for the iOS/Android
 * Paystack payment flow. The token encodes the user ID so the Netlify page
 * can identify who is paying without a backend session.
 *
 * @param {import('express').Request}  req - req.user set by auth middleware
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function generateSubscribeToken(req, res, next) {
  try {
    const { id: userId } = req.user;
    const data = paymentsService.generateSubscribeToken(userId);

    return res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

module.exports = { generateSubscribeToken };
