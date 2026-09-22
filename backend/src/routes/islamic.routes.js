/**
 * Islamic API routes — /api/v1/islamic
 * Proxies external Islamic APIs (Aladhan, alquran.cloud) with Redis caching.
 * All routes require authentication — Flutter never calls external APIs directly.
 */

'use strict';

const { Router } = require('express');
const { getPrayerTimes, getQuranSurah, getHadith } = require('../controllers/islamic.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  prayerTimesQuerySchema,
  surahParamSchema,
  hadithQuerySchema,
} = require('../validators/content.validator');

const router = Router();

router.use(authenticate);

// Query/path validation happens before the controller — lat/lng are
// interpolated into the Aladhan URL and must be numbers, not free text.
router.get('/prayer-times', validate(prayerTimesQuerySchema, 'query'), getPrayerTimes);
router.get('/quran/:surahNumber', validate(surahParamSchema, 'params'), getQuranSurah);
router.get('/hadith', validate(hadithQuerySchema, 'query'), getHadith);

module.exports = router;
