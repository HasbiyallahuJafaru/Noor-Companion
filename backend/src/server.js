/**
 * HTTP server entry point.
 * Initialises Sentry, Firebase, and starts listening on PORT.
 * Sentry must be initialised before any other imports.
 */

'use strict';

require('dotenv').config();

const { initSentry } = require('./config/sentry');
initSentry();

const { initFirebase } = require('./config/firebase');
initFirebase();

const { env } = require('./config/env');
const { app } = require('./app');
const { startStreakRiskWorker } = require('./workers/streakRisk.worker');
const { startCallTimeoutWorker } = require('./workers/callTimeout.worker');

const server = app.listen(env.PORT, () => {
  console.log(`✅  Noor Companion API running on port ${env.PORT} [${env.NODE_ENV}]`);
});

startStreakRiskWorker();
startCallTimeoutWorker();

function shutdown(signal) {
  console.log(`${signal} received — shutting down gracefully`);
  server.close(() => process.exit(0));
  // Keep-alive connections must not hold the process hostage.
  setTimeout(() => process.exit(0), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection:', reason);
});
