/**
 * Users controller — thin layer between routes and users service.
 * Receives validated request data, calls the service, returns responses.
 * Contains no business logic.
 */

'use strict';

const usersService = require('../services/users.service');

/**
 * GET /api/v1/users/me
 * Returns the authenticated user's profile including streak.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function getMe(req, res, next) {
  try {
    const user = await usersService.getMe(req.user.id);
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/users/me
 * Updates firstName, lastName, or avatarUrl.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function updateMe(req, res, next) {
  try {
    await usersService.updateProfile(req.user.id, req.body);
    return res.json({ success: true, data: { message: 'Profile updated.' } });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/users/me/fcm-token
 * Registers or updates the device FCM token.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function saveFcmToken(req, res, next) {
  try {
    await usersService.saveFcmToken(req.user.id, req.body.fcmToken);
    return res.json({ success: true, data: { message: 'FCM token registered.' } });
  } catch (err) {
    next(err);
  }
}

module.exports = { getMe, updateMe, saveFcmToken };
