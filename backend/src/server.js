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

process.on('SIGTERM', () => {
  console.log('SIGTERM received — shutting down gracefully');
  server.close(() => process.exit(0));
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection:', reason);
});
