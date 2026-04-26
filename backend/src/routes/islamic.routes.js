/**
 * Islamic API routes — /api/v1/islamic
 * Proxies external Islamic APIs (Aladhan, alquran.cloud) with Redis caching.
 * All routes require authentication — Flutter never calls external APIs directly.
 */

'use strict';

const { Router } = require('express');
const { getPrayerTimes, getQuranSurah, getHadith } = require('../controllers/islamic.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/prayer-times', getPrayerTimes);
router.get('/quran/:surahNumber', getQuranSurah);
router.get('/hadith', getHadith);

module.exports = router;
