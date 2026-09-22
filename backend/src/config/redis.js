/**
 * Redis client using ioredis — Railway Redis.
 * Backs response caching and the BullMQ queues (streak risk, call timeout).
 * Point REDIS_URL at Railway's private internal URL at runtime; TLS is
 * enabled automatically when the URL uses rediss:// (e.g. the public proxy).
 */

'use strict';

const Redis = require('ioredis');
const { env } = require('./env');

const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: null, // Required by BullMQ
  tls: env.REDIS_URL.startsWith('rediss://') ? {} : undefined,
});

redis.on('error', (err) => {
  console.error('[Redis] Connection error:', err.message);
});

module.exports = { redis };
