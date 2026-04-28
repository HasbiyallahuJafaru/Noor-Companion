/**
 * Streak risk worker — daily BullMQ job that sends FCM push notifications
 * to users whose streaks are at risk of breaking.
 *
 * Schedule: repeats daily at 20:00 UTC (8 PM).
 * Targets: users with currentStreak > 0 who have not engaged today.
 *
 * Call startStreakRiskWorker() from server.js at startup.
 * The queue and worker are created once and kept alive for the process lifetime.
 */

'use strict';

const { Queue, Worker } = require('bullmq');
const Sentry = require('@sentry/node');
const { redis } = require('../config/redis');
const { findStreakRiskUsers } = require('../services/streak.service');
const { admin } = require('../config/firebase');

const QUEUE_NAME = 'streakRisk';
const JOB_NAME = 'dailyStreakRisk';

/** FCM batch limit per multicast call */
const FCM_BATCH_SIZE = 500;

/**
 * Sends FCM push notifications to all at-risk users.
 * Batches into groups of 500 (FCM multicast limit).
 *
 * @returns {Promise<void>}
 */
async function runStreakRiskJob() {
  const users = await findStreakRiskUsers();

  if (users.length === 0) {
    console.log('[streakRisk] No at-risk users found.');
    return;
  }

  console.log(`[streakRisk] Sending risk push to ${users.length} users.`);

  for (let i = 0; i < users.length; i += FCM_BATCH_SIZE) {
    const batch = users.slice(i, i + FCM_BATCH_SIZE);
    await _sendBatch(batch);
  }
}

/**
 * Sends one FCM multicast message to a batch of at-risk users.
 * Logs failures per token without throwing — one bad token must not stop the batch.
 *
 * @param {Array<{userId: string, currentStreak: number, fcmToken: string}>} batch
 * @returns {Promise<void>}
 */
async function _sendBatch(batch) {
  const tokens = batch.map((u) => u.fcmToken);

  const message = {
    tokens,
    notification: {
      title: 'Your streak is at risk',
      body: _buildBody(batch),
    },
    data: { type: 'streak_reminder' },
    android: { priority: 'high' },
    apns: { payload: { aps: { 'content-available': 1 } } },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    response.responses.forEach((r, idx) => {
      if (!r.success) {
        console.warn(
          `[streakRisk] FCM failed for userId=${batch[idx].userId}: ${r.error?.message}`,
        );
      }
    });
  } catch (err) {
    Sentry.captureException(err);
    console.error('[streakRisk] FCM multicast error:', err.message);
  }
}

/**
 * Builds the notification body text.
 * When all users in a batch have the same streak, uses a personalised count.
 * Falls back to generic copy when streaks differ within a batch.
 *
 * @param {Array<{currentStreak: number}>} batch
 * @returns {string}
 */
function _buildBody(batch) {
  if (batch.length === 1) {
    return `Your ${batch[0].currentStreak}-day streak is at risk. Open Noor Companion before midnight.`;
  }
  return 'Your streak is at risk of breaking. Open Noor Companion before midnight.';
}

/**
 * Starts the streak risk queue and worker.
 * Enqueues the repeating job if it is not already scheduled.
 * Safe to call multiple times — guards against duplicate jobs.
 *
 * @returns {{ queue: Queue, worker: Worker }}
 */
function startStreakRiskWorker() {
  const connection = redis;

  const queue = new Queue(QUEUE_NAME, { connection });

  const worker = new Worker(
    QUEUE_NAME,
    async () => {
      await runStreakRiskJob();
    },
    { connection },
  );

  worker.on('completed', () => {
    console.log('[streakRisk] Job completed.');
  });

  worker.on('failed', (job, err) => {
    Sentry.captureException(err);
    console.error(`[streakRisk] Job failed: ${err.message}`);
  });

  _scheduleRepeatingJob(queue).catch((err) => {
    Sentry.captureException(err);
    console.error('[streakRisk] Failed to schedule job:', err.message);
  });

  return { queue, worker };
}

/**
 * Adds the daily repeating job to the queue if it is not already present.
 * Uses a stable job ID so restarts do not create duplicate schedules.
 *
 * Cron: '0 20 * * *' → 8:00 PM UTC every day.
 *
 * @param {Queue} queue
 * @returns {Promise<void>}
 */
async function _scheduleRepeatingJob(queue) {
  const existing = await queue.getRepeatableJobs();
  const alreadyScheduled = existing.some((j) => j.name === JOB_NAME);

  if (alreadyScheduled) return;

  await queue.add(
    JOB_NAME,
    {},
    {
      repeat: { pattern: '0 20 * * *' },
      jobId: 'streak-risk-daily',
    },
  );

  console.log('[streakRisk] Daily 8 PM UTC job scheduled.');
}

module.exports = { startStreakRiskWorker };
