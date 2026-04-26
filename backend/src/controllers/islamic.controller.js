/**
 * Islamic controller — thin layer between routes and Islamic service.
 * Handles prayer times, Quran, and hadith endpoints.
 * Contains no business logic — delegates entirely to Islamic service.
 */

'use strict';

const islamicService = require('../services/islamic.service');

/**
 * GET /api/v1/islamic/prayer-times
 * Returns prayer times for the given coordinates and optional date.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function getPrayerTimes(req, res, next) {
  try {
    const { lat, lng, date } = req.query;
    const result = await islamicService.getPrayerTimes(lat, lng, date);
    return res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/islamic/quran/:surahNumber
 * Returns a full surah with Arabic text, English translation, and audio URLs.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function getQuranSurah(req, res, next) {
  try {
    const surahNumber = parseInt(req.params.surahNumber, 10);
    const result = await islamicService.getQuranSurah(surahNumber);
    return res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/islamic/hadith
 * Returns a curated list of hadiths, optionally filtered by collection.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function getHadith(req, res, next) {
  try {
    const { collection, limit } = req.query;
    const results = await islamicService.getHadith(collection, limit);
    return res.json({ success: true, data: results });
  } catch (err) {
    next(err);
  }
}

module.exports = { getPrayerTimes, getQuranSurah, getHadith };
