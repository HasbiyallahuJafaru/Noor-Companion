/**
 * Content routes — /api/v1/content
 * Serves dhikr, duas, recitations from the database with Redis caching.
 * All routes require authentication.
 */

'use strict';

const { Router } = require('express');
const { listDhikr, listDuas, listRecitations, recordProgress } = require('../controllers/content.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/dhikr', listDhikr);
router.get('/duas', listDuas);
router.get('/recitations', listRecitations);
router.post('/:contentId/progress', recordProgress);

module.exports = router;
