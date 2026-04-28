/**
 * Zod validators for the /api/v1/calls endpoints.
 * initiateCallSchema: POST /calls/token request body.
 * rateCallSchema: POST /calls/:sessionId/rate request body.
 */

'use strict';

const { z } = require('zod');

/** POST /calls/token */
const initiateCallSchema = z.object({
  therapistProfileId: z.string().min(1, 'therapistProfileId is required.'),
});

/** POST /calls/:sessionId/rate */
const rateCallSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(500).optional(),
});

module.exports = { initiateCallSchema, rateCallSchema };
