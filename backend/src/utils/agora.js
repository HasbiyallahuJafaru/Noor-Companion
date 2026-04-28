/**
 * Agora utility — generates short-lived RTC tokens for call sessions.
 * Tokens are channel-specific and expire after 1 hour.
 * Never store generated tokens — generate on demand per session.
 *
 * Requires: AGORA_APP_ID and AGORA_APP_CERTIFICATE env vars.
 */

'use strict';

const { RtcTokenBuilder, RtcRole } = require('agora-token');

/** Token validity: 1 hour from generation time */
const TOKEN_EXPIRY_SECONDS = 3600;

/**
 * Generates an Agora RTC token for a specific channel.
 * Both caller and recipient use uid = 0 (Agora auto-assigns unique IDs).
 *
 * @param {string} channelName - Unique channel name (format: noor_<cuid>)
 * @returns {string} Signed Agora RTC token
 */
function generateRtcToken(channelName) {
  const currentTime = Math.floor(Date.now() / 1000);
  const expiryTime = currentTime + TOKEN_EXPIRY_SECONDS;

  return RtcTokenBuilder.buildTokenWithUid(
    process.env.AGORA_APP_ID,
    process.env.AGORA_APP_CERTIFICATE,
    channelName,
    0,
    RtcRole.PUBLISHER,
    expiryTime,
    expiryTime,
  );
}

module.exports = { generateRtcToken };
