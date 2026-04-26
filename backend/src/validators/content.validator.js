/**
 * Zod validation schemas for content and Islamic API routes.
 * Used via the validate() middleware factory.
 */

'use strict';

const { z } = require('zod');

/** Schema for recording progress on a content item (no body required). */
const progressSchema = z.object({});

/**
 * Schema for prayer-times query params.
 * lat and lng are required; date is optional.
 */
const prayerTimesQuerySchema = z.object({
  lat: z.string().regex(/^-?\d+(\.\d+)?$/, 'lat must be a number'),
  lng: z.string().regex(/^-?\d+(\.\d+)?$/, 'lng must be a number'),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD').optional(),
});

/** Schema for Quran surah number path param. */
const surahParamSchema = z.object({
  surahNumber: z.string().regex(/^\d+$/, 'surahNumber must be an integer'),
});

/** Schema for hadith query params. */
const hadithQuerySchema = z.object({
  collection: z.string().optional(),
  limit: z.string().regex(/^\d+$/).optional(),
});

/** Schema for content tag query param. */
const contentQuerySchema = z.object({
  tag: z.string().max(64).optional(),
});

module.exports = {
  progressSchema,
  prayerTimesQuerySchema,
  surahParamSchema,
  hadithQuerySchema,
  contentQuerySchema,
};
