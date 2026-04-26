/**
 * Islamic API service — proxies and caches external API calls.
 * Sources: Aladhan API (prayer times), alquran.cloud (Quran + audio).
 * Hadith is returned from a static curated set (no external dependency).
 *
 * Flutter never calls these external APIs directly — all requests go through
 * this backend so we control caching, rate limiting, and error surfaces.
 */

'use strict';

const { redis } = require('../config/redis');

const PRAYER_TIMES_TTL = 86400; // 24 hours — times don't change within a day
const QURAN_TTL = 86400;        // 24 hours — Quran text is immutable

const ALADHAN_BASE = 'https://api.aladhan.com/v1';
const ALQURAN_BASE = 'https://api.alquran.cloud/v1';
const ALQURAN_AUDIO_BASE = 'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/64';

/**
 * Fetches prayer times for a given coordinate and date.
 * Results are cached per lat/lng/date combination for 24 hours.
 *
 * @param {string} lat
 * @param {string} lng
 * @param {string|undefined} date - YYYY-MM-DD, defaults to today
 * @returns {Promise<object>}
 */
async function getPrayerTimes(lat, lng, date) {
  const resolvedDate = date || formatDate(new Date());
  const cacheKey = `prayer:${lat}:${lng}:${resolvedDate}`;

  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const url = `${ALADHAN_BASE}/timings/${resolvedDate}?latitude=${lat}&longitude=${lng}&method=2`;
  const response = await fetch(url);

  if (!response.ok) {
    const err = new Error('Prayer times API unavailable.');
    err.statusCode = 502;
    err.code = 'INTERNAL_ERROR';
    throw err;
  }

  const json = await response.json();
  const timings = json?.data?.timings;

  if (!timings) {
    const err = new Error('Unexpected response from prayer times API.');
    err.statusCode = 502;
    err.code = 'INTERNAL_ERROR';
    throw err;
  }

  const result = {
    date: resolvedDate,
    fajr: timings.Fajr,
    sunrise: timings.Sunrise,
    dhuhr: timings.Dhuhr,
    asr: timings.Asr,
    maghrib: timings.Maghrib,
    isha: timings.Isha,
  };

  await redis.setex(cacheKey, PRAYER_TIMES_TTL, JSON.stringify(result));
  return result;
}

/**
 * Returns a surah with all ayahs, translations, and audio URLs.
 * Cached 24 hours — Quran text is immutable.
 *
 * @param {number} surahNumber - 1 to 114
 * @returns {Promise<object>}
 */
async function getQuranSurah(surahNumber) {
  if (surahNumber < 1 || surahNumber > 114) {
    const err = new Error('Surah number must be between 1 and 114.');
    err.statusCode = 400;
    err.code = 'VALIDATION_ERROR';
    throw err;
  }

  const cacheKey = `quran:surah:${surahNumber}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const [arabicRes, translationRes] = await Promise.all([
    fetch(`${ALQURAN_BASE}/surah/${surahNumber}`),
    fetch(`${ALQURAN_BASE}/surah/${surahNumber}/en.asad`),
  ]);

  if (!arabicRes.ok || !translationRes.ok) {
    const err = new Error('Quran API unavailable.');
    err.statusCode = 502;
    err.code = 'INTERNAL_ERROR';
    throw err;
  }

  const [arabicJson, translationJson] = await Promise.all([
    arabicRes.json(),
    translationRes.json(),
  ]);

  const surah = arabicJson?.data;
  const translationSurah = translationJson?.data;

  if (!surah || !translationSurah) {
    const err = new Error('Unexpected response from Quran API.');
    err.statusCode = 502;
    err.code = 'INTERNAL_ERROR';
    throw err;
  }

  const verses = surah.ayahs.map((ayah, i) => ({
    number: ayah.numberInSurah,
    arabic: ayah.text,
    translation: translationSurah.ayahs[i]?.text ?? '',
    audioUrl: `${ALQURAN_AUDIO_BASE}/${ayah.number}.mp3`,
  }));

  const result = {
    number: surah.number,
    name: surah.name,
    englishName: surah.englishName,
    numberOfAyahs: surah.numberOfAyahs,
    verses,
  };

  await redis.setex(cacheKey, QURAN_TTL, JSON.stringify(result));
  return result;
}

/**
 * Returns a curated list of hadiths.
 * Static dataset — no external API call needed.
 *
 * @param {string|undefined} collection - Optional filter by collection name
 * @param {number} limit - Max items to return (default 10)
 * @returns {Promise<object[]>}
 */
async function getHadith(collection, limit) {
  const count = Math.min(Number(limit) || 10, 50);
  let results = HADITH_DATASET;

  if (collection) {
    const normalised = collection.toLowerCase();
    results = results.filter((h) => h.collection.toLowerCase() === normalised);
  }

  return results.slice(0, count);
}

/**
 * Formats a Date as YYYY-MM-DD in UTC.
 *
 * @param {Date} d
 * @returns {string}
 */
function formatDate(d) {
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(d.getUTCDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

// ─── Static Hadith Dataset ────────────────────────────────────────────────────

const HADITH_DATASET = [
  {
    id: 'bukhari:1',
    collection: 'Bukhari',
    arabic: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
    english: 'Actions are judged by intentions, and every person will get the reward according to what they intended.',
  },
  {
    id: 'muslim:2553',
    collection: 'Muslim',
    arabic: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ',
    english: 'A Muslim is the one from whose tongue and hands other Muslims are safe.',
  },
  {
    id: 'bukhari:6018',
    collection: 'Bukhari',
    arabic: 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ',
    english: 'The strong person is not the one who overcomes others by wrestling, but the one who controls himself when angry.',
  },
  {
    id: 'tirmidhi:2517',
    collection: 'Tirmidhi',
    arabic: 'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ',
    english: 'Fear Allah wherever you are, follow a bad deed with a good one and it will erase it, and treat people with good character.',
  },
  {
    id: 'muslim:223',
    collection: 'Muslim',
    arabic: 'الطَّهُورُ شَطْرُ الإِيمَانِ',
    english: 'Cleanliness is half of faith.',
  },
  {
    id: 'bukhari:6094',
    collection: 'Bukhari',
    arabic: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
    english: 'Whoever believes in Allah and the Last Day should say what is good or remain silent.',
  },
  {
    id: 'nasai:3104',
    collection: "Nasa'i",
    arabic: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
    english: 'The best of you are those who learn the Quran and teach it.',
  },
  {
    id: 'muslim:2699',
    collection: 'Muslim',
    arabic: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ',
    english: 'Whoever travels a path in search of knowledge, Allah will make easy for them a path to Paradise.',
  },
  {
    id: 'tirmidhi:2004',
    collection: 'Tirmidhi',
    arabic: 'أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا',
    english: 'The most complete of the believers in faith are those with the best character.',
  },
  {
    id: 'bukhari:5765',
    collection: 'Bukhari',
    arabic: 'لاَ يَشْكُرُ اللَّهَ مَنْ لاَ يَشْكُرُ النَّاسَ',
    english: 'Whoever does not thank people has not thanked Allah.',
  },
];

module.exports = { getPrayerTimes, getQuranSurah, getHadith };
