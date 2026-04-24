# PAYMENTS.md — Noor Companion
# Paystack integration — iOS Netlify redirect and Android in-app WebView.
# Read this before writing any payment-related code.

## Overview

Paystack is the sole payment processor.
Apple prohibits third-party in-app payment processors on iOS.
Android has no such restriction.

Both flows share the same Netlify subscribe page and the same
Paystack webhook handler. Only the client-side entry point differs.

---

## iOS Flow — Safari Redirect via Netlify

```
Flutter (iOS)
  → POST /api/v1/users/me/subscribe-token
  → Backend returns signed redirectUrl

  → url_launcher opens Safari:
    https://noorcompanion.netlify.app/subscribe?token=JWT&plan=paid

  → Netlify subscribe.html:
    1. Extracts token from URL
    2. POST /api/v1/payments/subscribe-init { token, plan }
    3. Backend verifies token, returns { email, amountInKobo, reference, userId }
    4. Paystack inline initialises with those values + metadata: { userId }

  → User pays on Paystack

  → Paystack webhook → POST /api/v1/payments/webhook (on backend)
    1. Verify HMAC signature
    2. Extract userId from event.data.metadata.userId
    3. Update user.subscriptionTier = 'paid' in Supabase
    4. Invalidate Redis user cache
    5. Send FCM push: "Subscription active"
    6. Return 200

  → User returns to Flutter app (app resumes)
    → App polls GET /api/v1/users/me up to 5 times (2s intervals)
    → Reflects paid tier when confirmed
```

---

## Android Flow — In-App WebView

```
Flutter (Android)
  → POST /api/v1/users/me/subscribe-token (same as iOS)
  → flutter_inappwebview opens:
    https://noorcompanion.netlify.app/subscribe?token=JWT&plan=paid

  → Same Netlify page, same Paystack flow as iOS

  → Paystack redirects to success URL on payment
  → App intercepts the redirect via shouldOverrideUrlLoading
  → WebView closes
  → App calls GET /api/v1/users/me to reflect new tier
```

---

## Backend: Subscribe Token Endpoint

```javascript
/**
 * POST /api/v1/users/me/subscribe-token
 *
 * Generates a short-lived signed token for the iOS/Android payment redirect.
 * The token encodes the user ID and plan so the Netlify page can identify
 * who is paying without requiring a separate backend session.
 *
 * Token expires in 10 minutes — short enough to prevent reuse,
 * long enough for the user to complete payment.
 *
 * @route POST /api/v1/users/me/subscribe-token
 * @access Auth required
 */
async function generateSubscribeToken(req, res, next) {
  try {
    const { id: userId } = req.user;

    const token = jwt.sign(
      { userId, plan: 'paid', purpose: 'paystack_redirect' },
      process.env.SUBSCRIPTION_TOKEN_SECRET,
      { expiresIn: '10m' }
    );

    const redirectUrl =
      `${process.env.WEBSITE_URL}/subscribe?token=${token}&plan=paid`;

    return res.json({
      success: true,
      data: { redirectUrl },
    });
  } catch (error) {
    next(error);
  }
}
```

---

## Backend: Subscribe Init Endpoint

Called by the Netlify subscribe page to verify the token and
return the data Paystack needs to initialise checkout.

```javascript
/**
 * POST /api/v1/payments/subscribe-init
 *
 * Verifies the signed redirect token and returns the data needed to
 * initialise the Paystack inline checkout on the Netlify page.
 *
 * This endpoint is called from the browser (Netlify page), not from Flutter.
 * It is authenticated by the signed token in the request body — not a Bearer token.
 *
 * @route POST /api/v1/payments/subscribe-init
 * @access Public (authenticated via signed token in body)
 */
async function subscribeInit(req, res, next) {
  try {
    const { token, plan } = req.body;

    // Verify and decode the signed token
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.SUBSCRIPTION_TOKEN_SECRET);
    } catch {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_TOKEN', message: 'Payment link is invalid or expired.' },
      });
    }

    if (decoded.purpose !== 'paystack_redirect') {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_TOKEN', message: 'Invalid token purpose.' },
      });
    }

    // Fetch the user's email from Supabase auth
    const { data: { user: supabaseUser } } = await supabase.auth.admin.getUserById(
      decoded.userId
    );

    if (!supabaseUser) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'User not found.' },
      });
    }

    // Get the plan amount — stored in DB for admin configurability
    // For now, hardcode until plan management is built
    const PAID_PLAN_AMOUNT_NGN = 5000; // NGN 5,000/month — update when client confirms
    const amountInKobo = PAID_PLAN_AMOUNT_NGN * 100;

    // Generate a unique payment reference
    const reference = `NR-${require('crypto').randomBytes(8).toString('hex')}`;

    return res.json({
      success: true,
      data: {
        email: supabaseUser.email,
        amountInKobo,
        reference,
        userId: decoded.userId,
      },
    });
  } catch (error) {
    next(error);
  }
}
```

---

## Backend: Paystack Webhook Handler

```javascript
/**
 * POST /api/v1/payments/webhook
 *
 * Receives Paystack webhook events.
 * HMAC signature verification happens before any processing.
 * Always responds 200 immediately — Paystack retries on non-200.
 *
 * IMPORTANT: This route must use express.raw() middleware, not express.json().
 * The raw body is needed for HMAC verification. See app.js setup below.
 *
 * @route POST /api/v1/payments/webhook
 * @access Public — verified via HMAC signature
 */
async function handleWebhook(req, res) {
  // Always respond 200 first to prevent Paystack retries
  res.status(200).json({ received: true });

  // Verify signature
  const signature = req.headers['x-paystack-signature'];
  const isValid = verifyPaystackWebhook(req.rawBody, signature);

  if (!isValid) {
    logger.warn('Invalid Paystack webhook signature — ignoring');
    return;
  }

  // Process the event asynchronously after responding
  try {
    const event = JSON.parse(req.rawBody);

    if (event.event === 'charge.success') {
      await processSuccessfulPayment(event.data);
    }
  } catch (error) {
    Sentry.captureException(error, {
      extra: { webhookEventId: JSON.parse(req.rawBody)?.id },
    });
  }
}

/**
 * Verifies the Paystack webhook HMAC-SHA512 signature.
 * Uses timing-safe comparison to prevent timing attacks.
 *
 * @param {Buffer} rawBody - The raw request body as a Buffer
 * @param {string} receivedSignature - The x-paystack-signature header value
 * @returns {boolean} True if valid
 */
function verifyPaystackWebhook(rawBody, receivedSignature) {
  const crypto = require('crypto');

  const expected = crypto
    .createHmac('sha512', process.env.PAYSTACK_SECRET_KEY)
    .update(rawBody)
    .digest('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected, 'hex'),
      Buffer.from(receivedSignature, 'hex')
    );
  } catch {
    return false;
  }
}

/**
 * Processes a successful Paystack payment.
 * Updates subscription tier, invalidates cache, sends push notification.
 * Idempotent — safe to call multiple times for the same event.
 *
 * @param {object} chargeData - event.data from the Paystack charge.success event
 */
async function processSuccessfulPayment(chargeData) {
  const { id: paystackEventId, metadata, amount, currency } = chargeData;
  const userId = metadata?.userId;

  if (!userId) {
    logger.error({ paystackEventId }, 'charge.success missing userId in metadata');
    return;
  }

  // Idempotency check — skip if this event was already processed
  const existing = await prisma.paymentEvent.findUnique({
    where: { paystackEventId },
  });

  if (existing) {
    logger.info({ paystackEventId }, 'Duplicate webhook — skipping');
    return;
  }

  // Run both writes in a transaction — all or nothing
  await prisma.$transaction([
    prisma.paymentEvent.create({
      data: {
        paystackEventId,
        userId,
        event: 'charge.success',
        amount,
        currency,
        status: 'success',
        rawPayload: chargeData,
      },
    }),
    prisma.user.update({
      where: { id: userId },
      data: { subscriptionTier: 'paid' },
    }),
  ]);

  // Bust the user cache so the next /me call returns the updated tier
  await redis.del(`user:${userId}`);

  // Notify the user
  await notificationService.sendToUser(userId, {
    type: 'subscription_active',
    title: 'Welcome to Noor Companion Premium',
    body: 'You now have access to therapist calling and all premium features.',
  });
}
```

---

## app.js — Webhook Raw Body Setup

Express's json() middleware destroys the raw body needed for HMAC verification.
The webhook route must be registered BEFORE the general json() middleware.

```javascript
// app.js — register webhook route first with raw body parser
app.post(
  '/api/v1/payments/webhook',
  express.raw({ type: 'application/json' }),
  webhookController.handleWebhook
);

// Then the general json parser for all other routes
app.use(express.json({ limit: '10mb' }));
```

---

## Netlify Subscribe Page (subscribe.html + subscribe.js)

```javascript
// website/js/subscribe.js

/**
 * Subscribe page logic.
 * Runs when the page loads at /subscribe?token=...&plan=paid
 *
 * Flow:
 * 1. Verify the signed token with the backend
 * 2. Initialise Paystack inline checkout
 * 3. On success: show return-to-app message
 * 4. On cancel: show retry option
 */
async function initSubscribePage() {
  const params = new URLSearchParams(window.location.search);
  const token = params.get('token');
  const plan = params.get('plan');

  if (!token || !plan) {
    showError('Invalid payment link. Please return to the app and try again.');
    return;
  }

  let paymentData;
  try {
    const response = await fetch(`${API_BASE_URL}/api/v1/payments/subscribe-init`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token, plan }),
    });

    const json = await response.json();

    if (!json.success) {
      showError(json.error.message || 'Payment link has expired. Please try again.');
      return;
    }

    paymentData = json.data;
  } catch {
    showError('Connection error. Please check your internet and try again.');
    return;
  }

  // Initialise Paystack inline checkout
  // The public key is safe to include in client-side code
  const handler = PaystackPop.setup({
    key: PAYSTACK_PUBLIC_KEY,
    email: paymentData.email,
    amount: paymentData.amountInKobo,
    ref: paymentData.reference,
    currency: 'NGN',
    metadata: {
      userId: paymentData.userId,
      plan: plan,
    },
    callback: function (response) {
      // Payment completed — show success screen
      document.getElementById('loading-screen').style.display = 'none';
      document.getElementById('success-screen').style.display = 'flex';
    },
    onClose: function () {
      // User closed checkout without paying
      document.getElementById('loading-screen').style.display = 'none';
      document.getElementById('cancelled-screen').style.display = 'flex';
    },
  });

  handler.openIframe();
}
```
