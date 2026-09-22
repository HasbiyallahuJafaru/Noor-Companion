/**
 * Content routes — /api/v1/content
 * Serves dhikr, duas, recitations from the database with Redis caching.
 * All routes require authentication.
 */

'use strict';

const { Router } = require('express');
const { listDhikr, listDuas, listRecitations, recordProgress } = require('../controllers/content.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { contentQuerySchema } = require('../validators/content.validator');

const router = Router();

router.use(authenticate);

router.get('/dhikr', validate(contentQuerySchema, 'query'), listDhikr);
router.get('/duas', validate(contentQuerySchema, 'query'), listDuas);
router.get('/recitations', validate(contentQuerySchema, 'query'), listRecitations);
router.post('/:contentId/progress', recordProgress);

module.exports = router;
