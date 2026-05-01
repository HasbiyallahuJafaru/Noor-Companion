/**
 * payments.controller.js — thin request/response layer for payment endpoints.
 * All business logic lives in payments.service.js.
 * This controller handles webhook raw-body parsing and async error forwarding.
 */

'use strict';

const logger = console; // Replace with pino if added later
const paymentsService = require('../services/payments.service');

// ── Subscribe init ────────────────────────────────────────────────────────────

/**
 * POST /api/v1/payments/subscribe-init
 *
 * Called by the Netlify subscribe page to verify the redirect token
 * and receive the initialisation data for Paystack inline checkout.
 * Authenticated via signed JWT in body — no Bearer token required.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function subscribeInit(req, res, next) {
  try {
    const { token, plan } = req.body;
    const data = await paymentsService.verifySubscribeInit(token, plan);

    return res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

// ── Webhook ───────────────────────────────────────────────────────────────────

/**
 * POST /api/v1/payments/webhook
 *
 * Receives Paystack webhook events.
 * Always responds 200 immediately — Paystack retries on any non-200 response.
 * HMAC signature is verified after responding to avoid blocking Paystack.
 *
 * @param {import('express').Request}  req
 * @param {import('express').Response} res
 */
async function handleWebhook(req, res) {
  res.status(200).json({ received: true });

  const signature = req.headers['x-paystack-signature'];
  const isValid = paymentsService.verifyPaystackWebhook(req.body, signature);

  if (!isValid) {
    logger.warn('[webhook] Invalid Paystack signature — ignoring');
    return;
  }

  let event;
  try {
    event = JSON.parse(req.body.toString());
  } catch (err) {
    logger.error('[webhook] JSON parse error:', err.message);
    return;
  }

  try {
    if (event.event === 'charge.success') {
      await paymentsService.processSuccessfulPayment(event.data);
    }
  } catch (err) {
    logger.error('[webhook] processSuccessfulPayment error:', err.message);
  }
}

module.exports = { subscribeInit, handleWebhook };
