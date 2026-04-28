/**
 * payments.validator.js — Zod schemas for payment-related endpoints.
 * Used by the payments controller via the validate() middleware.
 */

'use strict';

const { z } = require('zod');

/**
 * Schema for POST /api/v1/payments/subscribe-init.
 * Called by the Netlify subscribe page — not from Flutter directly.
 * Validates the signed token and plan identifier.
 */
const subscribeInitSchema = z.object({
  token: z.string().min(1, 'Token is required.'),
  plan: z.enum(['paid'], { error: 'Invalid plan.' }),
});

module.exports = { subscribeInitSchema };
