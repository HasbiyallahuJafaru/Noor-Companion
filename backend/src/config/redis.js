/**
 * Upstash Redis client using ioredis.
 * Used for caching API responses and as BullMQ queue backing store.
 */

'use strict';

const Redis = require('ioredis');
const { env } = require('./env');

const redis = new Redis(env.UPSTASH_REDIS_URL, {
  maxRetriesPerRequest: null, // Required by BullMQ
  tls: env.UPSTASH_REDIS_URL.startsWith('rediss://') ? {} : undefined,
});

redis.on('error', (err) => {
  console.error('[Redis] Connection error:', err.message);
});

module.exports = { redis };
