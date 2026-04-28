/**
 * Zod validators for therapist endpoints.
 * Used by therapists.routes.js and admin.routes.js.
 */

'use strict';

const { z } = require('zod');

/**
 * Query params for GET /api/v1/therapists.
 */
const listTherapistsSchema = z.object({
  specialisation: z.string().trim().optional(),
  language: z.string().trim().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

/**
 * Body for POST /api/v1/therapists/profile.
 * Used to create or update a therapist's own profile.
 */
const upsertProfileSchema = z.object({
  bio: z.string().trim().min(10).max(1000),
  specialisations: z.array(z.string().trim().min(1)).min(1).max(10),
  qualifications: z.array(z.string().trim().min(1)).min(1).max(10),
  yearsExperience: z.number().int().min(0).max(60),
  languagesSpoken: z.array(z.string().trim().min(1)).min(1).max(10),
  sessionRateNgn: z.number().int().min(0),
  availabilityJson: z.record(z.unknown()).optional(),
});

/**
 * Body for POST /api/v1/admin/therapists/:id/reject.
 */
const rejectTherapistSchema = z.object({
  reason: z.string().trim().min(5).max(500),
});

module.exports = { listTherapistsSchema, upsertProfileSchema, rejectTherapistSchema };
