/**
 * Zod validators for admin-only endpoints.
 * All schemas are used exclusively in admin.routes.js.
 */

'use strict';

const { z } = require('zod');

/**
 * Query params for GET /api/v1/admin/users.
 */
const listUsersSchema = z.object({
  role: z.enum(['user', 'therapist', 'admin']).optional(),
  subscriptionTier: z.enum(['free', 'paid']).optional(),
  search: z.string().trim().max(100).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

/**
 * Body for PATCH /api/v1/admin/users/:userId.
 * At least one field must be present.
 */
const updateUserSchema = z
  .object({
    isActive: z.boolean().optional(),
    subscriptionTier: z.enum(['free', 'paid']).optional(),
  })
  .refine((d) => d.isActive !== undefined || d.subscriptionTier !== undefined, {
    message: 'At least one of isActive or subscriptionTier must be provided.',
  });

/**
 * Body for POST /api/v1/admin/content.
 */
const createContentSchema = z.object({
  title: z.string().trim().min(1).max(200),
  arabicText: z.string().trim().min(1),
  transliteration: z.string().trim().min(1).max(500),
  translation: z.string().trim().min(1).max(1000),
  audioUrl: z.string().url().optional(),
  category: z.enum(['dhikr', 'dua', 'recitation']),
  tags: z.array(z.string().trim().min(1)).min(1).max(10),
  sortOrder: z.number().int().min(0).default(0),
});

/**
 * Body for PATCH /api/v1/admin/content/:contentId.
 * All fields are optional — toggle isActive alone is a valid call.
 */
const updateContentSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    isActive: z.boolean().optional(),
    sortOrder: z.number().int().min(0).optional(),
    tags: z.array(z.string().trim().min(1)).min(1).max(10).optional(),
    audioUrl: z.string().url().nullable().optional(),
  })
  .refine((d) => Object.values(d).some((v) => v !== undefined), {
    message: 'At least one field must be provided.',
  });

/**
 * Query params for GET /api/v1/admin/content.
 */
const listContentSchema = z.object({
  category: z.enum(['dhikr', 'dua', 'recitation']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

/**
 * Body for POST /api/v1/admin/notifications/broadcast.
 */
const broadcastSchema = z.object({
  title: z.string().trim().min(1).max(200),
  body: z.string().trim().min(1).max(1000),
  targetRole: z.enum(['user', 'therapist', 'admin']),
});

module.exports = {
  listUsersSchema,
  updateUserSchema,
  createContentSchema,
  updateContentSchema,
  listContentSchema,
  broadcastSchema,
};
