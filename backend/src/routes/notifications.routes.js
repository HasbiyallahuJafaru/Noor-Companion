/**
 * notifications.routes.js — /api/v1/notifications
 * All routes require Supabase JWT authentication.
 */

'use strict';

const { Router } = require('express');
const { listNotifications, markAllRead } = require('../controllers/notifications.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/', listNotifications);
router.post('/read-all', markAllRead);

module.exports = router;
