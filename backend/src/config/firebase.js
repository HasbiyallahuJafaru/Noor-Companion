/**
 * Firebase Admin SDK initialisation.
 * Used only for sending FCM push notifications.
 * Call initFirebase() once from server.js at startup.
 */

'use strict';

const admin = require('firebase-admin');
const { env } = require('./env');

function initFirebase() {
  if (admin.apps.length > 0) return;

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
    }),
  });
}

module.exports = { initFirebase, admin };
