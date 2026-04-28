/**
 * payments.service.js — business logic for the Paystack subscription flow.
 *
 * Handles three concerns:
 *  1. Generating a short-lived signed redirect token for the iOS/Android payment page.
 *  2. Verifying that token and returning the data Paystack needs to initialise checkout.
 *  3. Processing a successful Paystack webhook — updating the user's tier, busting cache,
 *     sending push notification, and recording the payment event for audit.
 */

'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const Sentry = require('@sentry/node');
const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');
const { supabase } = require('../config/supabase');
const { env } = require('../config/env');
const notificationService = require('./notification.service');

const PAID_PLAN_AMOUNT_NGN = 5000; // ₦5,000/month — update when client confirms pricing

// ── Subscribe token ───────────────────────────────────────────────────────────

/**
 * Generates a short-lived JWT that encodes the user ID and intended plan.
 * The Netlify subscribe page sends this back to /payments/subscribe-init
 * to identify who is paying without requiring a Supabase session in the browser.
 *
 * Token expires in 10 minutes — enough time to complete payment.
 *
 * @param {string} userId - Our app User.id (CUID)
 * @returns {{ redirectUrl: string }} Absolute URL to the Netlify subscribe page
 */
function generateSubscribeToken(userId) {
  const token = jwt.sign(
    { userId, plan: 'paid', purpose: 'paystack_redirect' },
    env.SUBSCRIPTION_TOKEN_SECRET,
    { expiresIn: '10m' },
  );

  const redirectUrl = `${env.WEBSITE_URL}/subscribe?token=${token}&plan=paid`;
  return { redirectUrl };
}

// ── Subscribe init ────────────────────────────────────────────────────────────

/**
 * Verifies the signed redirect token and returns the data needed to
 * initialise the Paystack inline checkout on the Netlify page.
 *
 * Throws structured errors rather than returning them so the caller
 * can pass them to Express's next() and let the error handler respond.
 *
 * @param {string} token - The JWT from the subscribe page URL query string
 * @param {string} plan  - Must be 'paid'
 * @returns {Promise<{ email: string, amountInKobo: number, reference: string, userId: string }>}
 */
async function verifySubscribeInit(token, plan) {
  let decoded;

  try {
    decoded = jwt.verify(token, env.SUBSCRIPTION_TOKEN_SECRET);
  } catch {
    const err = new Error('Payment link is invalid or has expired.');
    err.statusCode = 400;
    err.code = 'INVALID_TOKEN';
    throw err;
  }

  if (decoded.purpose !== 'paystack_redirect' || decoded.plan !== plan) {
    const err = new Error('Invalid token purpose or plan.');
    err.statusCode = 400;
    err.code = 'INVALID_TOKEN';
    throw err;
  }

  const { data: { user: supabaseUser }, error } =
    await supabase.auth.admin.getUserById(decoded.userId);

  if (error || !supabaseUser) {
    const err = new Error('User not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  const amountInKobo = PAID_PLAN_AMOUNT_NGN * 100;
  const reference = `NR-${crypto.randomBytes(8).toString('hex')}`;

  return {
    email: supabaseUser.email,
    amountInKobo,
    reference,
    userId: decoded.userId,
  };
}

// ── Webhook ───────────────────────────────────────────────────────────────────

/**
 * Verifies the Paystack webhook HMAC-SHA512 signature using timing-safe comparison.
 * Must be called with the raw request body Buffer — not the parsed JSON.
 *
 * @param {Buffer}  rawBody           - The raw Express request body
 * @param {string}  receivedSignature - The x-paystack-signature header value
 * @returns {boolean} True if the signature is valid
 */
function verifyPaystackWebhook(rawBody, receivedSignature) {
  if (!receivedSignature) return false;

  const expected = crypto
    .createHmac('sha512', env.PAYSTACK_SECRET_KEY)
    .update(rawBody)
    .digest('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected, 'hex'),
      Buffer.from(receivedSignature, 'hex'),
    );
  } catch {
    return false;
  }
}

/**
 * Processes a successful Paystack charge event.
 * Idempotent — safe to call multiple times for the same event.
 *
 * Side effects:
 *  - Creates a PaymentEvent audit record
 *  - Updates User.subscriptionTier to 'paid'
 *  - Deletes the Redis user cache entry for the affected user
 *  - Sends an FCM push notification to the user
 *
 * @param {object} chargeData - The event.data object from a charge.success webhook
 */
async function processSuccessfulPayment(chargeData) {
  const { id: paystackEventId, metadata, amount, currency } = chargeData;
  const userId = metadata?.userId;

  if (!userId) {
    Sentry.captureMessage('charge.success webhook missing userId in metadata', {
      extra: { paystackEventId },
    });
    return;
  }

  const existing = await prisma.paymentEvent.findUnique({
    where: { paystackEventId: String(paystackEventId) },
    select: { id: true },
  });

  if (existing) return; // Duplicate event — skip silently

  await prisma.$transaction([
    prisma.paymentEvent.create({
      data: {
        paystackEventId: String(paystackEventId),
        userId,
        event: 'charge.success',
        amount: amount ?? 0,
        currency: currency ?? 'NGN',
        status: 'success',
        rawPayload: chargeData,
      },
    }),
    prisma.user.update({
      where: { id: userId },
      data: { subscriptionTier: 'paid' },
    }),
  ]);

  await redis.del(`user:${userId}`);

  await notificationService.sendToUser(userId, {
    type: 'subscription_active',
    title: 'Welcome to Noor Companion Premium',
    body: 'You now have access to therapist calling and all premium features.',
  });
}

module.exports = {
  generateSubscribeToken,
  verifySubscribeInit,
  verifyPaystackWebhook,
  processSuccessfulPayment,
};
