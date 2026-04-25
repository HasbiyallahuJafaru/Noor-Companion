/**
 * Sentry initialisation for error tracking.
 * Must be called before any other imports in server.js.
 */

'use strict';

const Sentry = require('@sentry/node');
const { env } = require('./env');

function initSentry() {
  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.NODE_ENV,
    tracesSampleRate: env.NODE_ENV === 'production' ? 0.1 : 1.0,
  });
}

module.exports = { initSentry, Sentry };
