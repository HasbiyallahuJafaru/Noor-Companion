/**
 * Call timeout worker — processes missed-call checks.
 * Fires 60 seconds after a call is initiated.
 * If the session is still 'initiated', the therapist didn't answer:
 * mark it 'missed' and send a push notification to the caller.
 *
 * Call startCallTimeoutWorker() from server.js at startup.
 */

'use strict';

const { Queue, Worker } = require('bullmq');
const { redis } = require('../config/redis');
const { prisma } = require('../config/prisma');
const { notificationService } = require('../services/notification.service');

const QUEUE_NAME = 'callTimeout';
const CALL_TIMEOUT_JOB = 'check-missed';

/**
 * Returns the shared callTimeout BullMQ queue for enqueuing timeout jobs.
 * Created once per process — a new Queue per call would churn Redis connections.
 *
 * @returns {Queue}
 */
let _queue;
function getCallTimeoutQueue() {
  if (!_queue) _queue = new Queue(QUEUE_NAME, { connection: redis });
  return _queue;
}

/**
 * Processes a single missed-call check job.
 * Marks session as 'missed' and notifies the caller if still 'initiated'.
 *
 * @param {{ data: { sessionId: string } }} job
 * @returns {Promise<void>}
 */
async function _processMissedCallCheck(job) {
  const { sessionId } = job.data;

  const session = await prisma.callSession.findUnique({
    where: { id: sessionId },
    select: { id: true, status: true, userId: true },
  });

  if (!session || session.status !== 'initiated') return;

  await prisma.callSession.update({
    where: { id: sessionId },
    data: { status: 'missed' },
  });

  await notificationService.sendToUser(session.userId, {
    type: 'general',
    title: 'Therapist Unavailable',
    body: 'The therapist was not available right now. Please try again later.',
  });
}

/**
 * Starts the call timeout worker.
 * The worker listens for delayed 'check-missed' jobs added by calling.service.
 *
 * @returns {{ queue: Queue, worker: Worker }}
 */
function startCallTimeoutWorker() {
  const queue = getCallTimeoutQueue();

  const worker = new Worker(QUEUE_NAME, _processMissedCallCheck, { connection: redis });

  worker.on('completed', (job) => {
    console.log(`[callTimeout] Job ${job.id} completed.`);
  });

  worker.on('failed', (job, err) => {
    console.error('[callTimeout] Job error:', err.message);
    console.error(`[callTimeout] Job failed: ${err.message}`);
  });

  return { queue, worker };
}

module.exports = { startCallTimeoutWorker, getCallTimeoutQueue, CALL_TIMEOUT_JOB };
