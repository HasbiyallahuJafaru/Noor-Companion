/**
 * Email utility using Resend.
 * Provides typed helpers for transactional emails sent by the backend.
 * All sends are fire-and-forget — failures are logged to Sentry, not re-thrown,
 * so a failed email never breaks the API response.
 */

'use strict';

const { Resend } = require('resend');
const { env } = require('../config/env');

// Emails are best-effort — a missing API key must not crash the server
// at import time; sends become logged no-ops instead.
const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : null;

/**
 * Sends an email via Resend, or logs and skips when not configured.
 *
 * @param {{ to: string, subject: string, html: string }} params
 * @returns {Promise<void>}
 */
async function _send({ to, subject, html }) {
  if (!resend) {
    console.warn(`[email] RESEND_API_KEY not set — skipped: "${subject}" to ${to}`);
    return;
  }
  if (!to) {
    console.warn(`[email] no recipient — skipped: "${subject}"`);
    return;
  }
  try {
    await resend.emails.send({ from: env.FROM_EMAIL, to, subject, html });
  } catch (err) {
    console.error(`[email] Failed to send "${subject}":`, err.message);
  }
}

/**
 * Sends a therapist approval notification email.
 *
 * @param {{ toEmail: string, firstName: string }} params
 * @returns {Promise<void>}
 */
async function sendTherapistApprovedEmail({ toEmail, firstName }) {
  await _send({ to: toEmail, subject: 'You\'re approved — Welcome to Noor Companion', html: _approvedHtml(firstName) });
}

/**
 * Sends a therapist rejection notification email.
 *
 * @param {{ toEmail: string, firstName: string, reason: string }} params
 * @returns {Promise<void>}
 */
async function sendTherapistRejectedEmail({ toEmail, firstName, reason }) {
  await _send({ to: toEmail, subject: 'Update on your Noor Companion application', html: _rejectedHtml(firstName, reason) });
}

/**
 * Returns the HTML body for the approval email.
 *
 * @param {string} firstName
 * @returns {string}
 */
function _approvedHtml(firstName) {
  return `
    <div style="font-family:sans-serif;max-width:520px;margin:0 auto;color:#1A2E2B">
      <h2 style="color:#0D7C6E">Assalamu alaikum, ${firstName}</h2>
      <p>
        Your application to join Noor Companion as a therapist has been
        <strong>approved</strong>. Alhamdulillah.
      </p>
      <p>
        You can now log in to the app. Your profile is live and users can
        connect with you for sessions.
      </p>
      <p style="color:#6B8A85;font-size:13px">
        Jazakallahu khairan for your service to the community.
      </p>
      <hr style="border:none;border-top:1px solid #DDE8E6;margin:24px 0"/>
      <p style="color:#6B8A85;font-size:12px">
        Noor Companion · Light your way back
      </p>
    </div>
  `;
}

/**
 * Returns the HTML body for the rejection email.
 *
 * @param {string} firstName
 * @param {string} reason
 * @returns {string}
 */
function _rejectedHtml(firstName, reason) {
  return `
    <div style="font-family:sans-serif;max-width:520px;margin:0 auto;color:#1A2E2B">
      <h2 style="color:#0D7C6E">Assalamu alaikum, ${firstName}</h2>
      <p>
        Thank you for applying to join Noor Companion as a therapist.
        After review, we are unable to approve your application at this time.
      </p>
      <p><strong>Reason:</strong> ${reason}</p>
      <p>
        If you believe this is an error or would like to reapply with
        additional information, please contact us at support@noorcompanion.com.
      </p>
      <hr style="border:none;border-top:1px solid #DDE8E6;margin:24px 0"/>
      <p style="color:#6B8A85;font-size:12px">
        Noor Companion · Light your way back
      </p>
    </div>
  `;
}

module.exports = { sendTherapistApprovedEmail, sendTherapistRejectedEmail };
