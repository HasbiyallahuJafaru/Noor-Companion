/**
 * Express application factory.
 * Registers middleware, routes, and error handlers.
 * Exported separately from server.js to enable testing without binding a port.
 */

'use strict';

require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { apiLimiter } = require('./middleware/rateLimiter');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const usersRoutes = require('./routes/users.routes');

const app = express();

// ── Security headers ──────────────────────────────────────────────────────────
app.use(helmet());

// ── CORS ──────────────────────────────────────────────────────────────────────
app.use(cors({
  origin: process.env.WEBSITE_URL || '*',
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ── Body parsing ──────────────────────────────────────────────────────────────
// Webhook route needs raw body for HMAC verification — keep it separate
app.use('/api/v1/payments/webhook', express.raw({ type: 'application/json' }));
app.use(express.json());

// ── Rate limiting ─────────────────────────────────────────────────────────────
app.use('/api/', apiLimiter);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok' } });
});

// ── API routes ────────────────────────────────────────────────────────────────
app.use('/api/v1/users', usersRoutes);

// ── 404 + error handler — must be last ───────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

module.exports = { app };
