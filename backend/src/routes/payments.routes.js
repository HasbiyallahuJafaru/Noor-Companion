/**
 * payments.routes.js — /api/v1/payments
 *
 * Two endpoints:
 *  POST /subscribe-init — called by Netlify page to verify token + get Paystack data
 *  POST /webhook        — called by Paystack with raw body for HMAC verification
 *
 * The webhook route uses express.raw() so it is registered in app.js BEFORE
 * express.json() — do not move the raw-body middleware to this file.
 */

'use strict';

const { Router } = require('express');
const { subscribeInit, handleWebhook } = require('../controllers/payments.controller');
const { validate } = require('../middleware/validate');
const { subscribeInitSchema } = require('../validators/payments.validator');

const router = Router();

/**
 * POST /api/v1/payments/subscribe-init
 * Public — authenticated by the signed JWT in the request body.
 * Called from the Netlify page, not from Flutter.
 */
router.post('/subscribe-init', validate(subscribeInitSchema), subscribeInit);

/**
 * POST /api/v1/payments/webhook
 * Public — authenticated via Paystack HMAC-SHA512 signature.
 * Raw body is read in app.js before express.json() runs.
 * Validation is intentionally omitted — raw body must not be parsed by Zod.
 */
router.post('/webhook', handleWebhook);

module.exports = router;
