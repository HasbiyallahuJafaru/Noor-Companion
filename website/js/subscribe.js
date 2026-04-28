/**
 * subscribe.js — Noor Companion payment page logic
 *
 * Flow:
 * 1. Extract ?token and ?plan from URL
 * 2. POST to backend /payments/subscribe-init to verify token
 * 3. Initialise Paystack inline checkout with returned data
 * 4. On success: show return-to-app confirmation screen
 * 5. On cancel: show retry screen
 */

(function () {
  'use strict';

  /** Backend API base URL — replaced at deploy time via Netlify env */
  var API_BASE_URL = window.NOOR_API_URL || 'https://api.noorcompanion.com';

  /** Paystack public key — safe to expose in client code */
  var PAYSTACK_PUBLIC_KEY = window.NOOR_PAYSTACK_PUBLIC_KEY || '';

  /** All screen IDs in the payment shell */
  var SCREENS = {
    loading:   'screen-loading',
    plan:      'screen-plan',
    success:   'screen-success',
    cancelled: 'screen-cancelled',
    error:     'screen-error',
  };

  /** Shows a single screen, hides the rest */
  function showScreen(screenId) {
    Object.values(SCREENS).forEach(function (id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.classList.toggle('active', id === screenId);
    });
  }

  /** Populates the error screen with a message and shows it */
  function showError(message) {
    var el = document.getElementById('error-message');
    if (el) el.textContent = message;
    showScreen(SCREENS.error);
  }

  /** Populates the plan card with pricing data before opening Paystack */
  function populatePlanCard(amountInKobo) {
    var priceEl = document.getElementById('plan-price-value');
    if (!priceEl) return;
    var formatted = (amountInKobo / 100).toLocaleString('en-NG', {
      style: 'currency',
      currency: 'NGN',
      minimumFractionDigits: 0,
    });
    priceEl.textContent = formatted;
  }

  /** Opens the Paystack inline checkout */
  function openPaystack(paymentData) {
    if (typeof PaystackPop === 'undefined') {
      showError('Payment provider failed to load. Please refresh and try again.');
      return;
    }

    if (!PAYSTACK_PUBLIC_KEY) {
      showError('Payment configuration error. Please contact support.');
      return;
    }

    var handler = PaystackPop.setup({
      key:      PAYSTACK_PUBLIC_KEY,
      email:    paymentData.email,
      amount:   paymentData.amountInKobo,
      ref:      paymentData.reference,
      currency: 'NGN',
      label:    'Noor Companion Premium',
      metadata: {
        userId:   paymentData.userId,
        plan:     'paid',
        custom_fields: [
          {
            display_name: 'App',
            variable_name: 'app',
            value: 'Noor Companion',
          },
        ],
      },
      callback: function () {
        showScreen(SCREENS.success);
        // Signal the Android WebView to close and refresh tier.
        // On iOS Safari this is a no-op (Safari ignores unknown schemes silently).
        window.location.href = 'noorcompanion://payment-success';
      },
      onClose: function () {
        showScreen(SCREENS.cancelled);
      },
    });

    handler.openIframe();
  }

  /** Main entry — called on DOMContentLoaded */
  async function init() {
    showScreen(SCREENS.loading);

    var params = new URLSearchParams(window.location.search);
    var token  = params.get('token');
    var plan   = params.get('plan');

    if (!token || !plan) {
      showError('Invalid payment link. Please return to the app and try again.');
      return;
    }

    var paymentData;

    try {
      var response = await fetch(API_BASE_URL + '/api/v1/payments/subscribe-init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: token, plan: plan }),
      });

      var json = await response.json();

      if (!json.success) {
        var message = (json.error && json.error.message)
          ? json.error.message
          : 'Payment link has expired. Please return to the app and try again.';
        showError(message);
        return;
      }

      paymentData = json.data;
    } catch (err) {
      showError('Connection error. Please check your internet and try again.');
      return;
    }

    populatePlanCard(paymentData.amountInKobo);
    showScreen(SCREENS.plan);

    /* Small delay so user sees the plan card before checkout opens */
    setTimeout(function () {
      openPaystack(paymentData);
    }, 800);
  }

  document.addEventListener('DOMContentLoaded', init);
}());
