/**
 * Zod validation schemas for user routes.
 */

'use strict';

const { z } = require('zod');

const updateProfileSchema = z.object({
  firstName: z.string().min(1).max(100).optional(),
  lastName: z.string().min(1).max(100).optional(),
  avatarUrl: z.string().url().optional().nullable(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field is required.' }
);

const fcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'FCM token is required.'),
});

module.exports = { updateProfileSchema, fcmTokenSchema };
