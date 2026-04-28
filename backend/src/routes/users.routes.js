/**
 * User routes — /api/v1/users
 * All routes require Supabase JWT authentication.
 */

'use strict';

const { Router } = require('express');
const { getMe, updateMe, saveFcmToken } = require('../controllers/users.controller');
const { generateSubscribeToken } = require('../controllers/subscribe_token.controller');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { writeLimiter } = require('../middleware/rateLimiter');
const { updateProfileSchema, fcmTokenSchema } = require('../validators/users.validator');

const router = Router();

router.use(authenticate);

router.get('/me', getMe);
router.patch('/me', validate(updateProfileSchema), updateMe);
router.post('/me/fcm-token', writeLimiter, validate(fcmTokenSchema), saveFcmToken);
router.post('/me/subscribe-token', writeLimiter, generateSubscribeToken);

module.exports = router;
