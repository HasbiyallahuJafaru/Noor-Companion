/**
 * Global error handler — registered as the last middleware in app.js.
 * Formats all errors into the standard { success: false, error: { code, message } } shape.
 * Never leaks stack traces or internal Prisma errors to the client.
 */

'use strict';

const { Sentry } = require('../config/sentry');

/**
 * Catches errors thrown or passed to next() anywhere in the app.
 *
 * @param {Error} err
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} _next
 */
function errorHandler(err, req, res, _next) {
  const statusCode = err.statusCode || 500;
  const code = err.code || 'INTERNAL_ERROR';
  const message = statusCode >= 500
    ? 'An unexpected error occurred.'
    : err.message;

  if (statusCode >= 500) {
    Sentry.captureException(err);
    console.error('[Error]', err);
  }

  return res.status(statusCode).json({
    success: false,
    error: { code, message },
  });
}

/** 404 handler — registered before errorHandler in app.js. */
function notFound(req, res) {
  return res.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: `Route ${req.method} ${req.path} not found.` },
  });
}

module.exports = { errorHandler, notFound };
