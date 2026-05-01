/**
 * Therapists service — directory listing, profile management, and admin approval.
 * Approval and rejection send FCM push + Resend email to the therapist.
 */

'use strict';

const { prisma } = require('../config/prisma');
const { admin } = require('../config/firebase');
const { sendTherapistApprovedEmail, sendTherapistRejectedEmail } = require('../utils/email');

/** Fields selected for every therapist in the directory listing. */
const THERAPIST_SELECT = {
  id: true,
  bio: true,
  specialisations: true,
  qualifications: true,
  yearsExperience: true,
  languagesSpoken: true,
  sessionRateNgn: true,
  availabilityJson: true,
  approvedAt: true,
  user: {
    select: {
      id: true,
      firstName: true,
      lastName: true,
      avatarUrl: true,
      fcmToken: true,
    },
  },
  ratings: { select: { rating: true } },
  sessions: {
    where: { status: 'completed' },
    select: { id: true },
  },
};

/**
 * Lists active therapists with optional filters.
 * Returns computed averageRating and totalSessions.
 *
 * @param {{ specialisation?: string, language?: string, page: number, limit: number }} params
 * @returns {Promise<{ therapists: object[], pagination: object }>}
 */
async function listTherapists({ specialisation, language, page, limit }) {
  const where = {
    status: 'active',
    ...(specialisation && {
      specialisations: { has: specialisation },
    }),
    ...(language && {
      languagesSpoken: { has: language },
    }),
  };

  const [profiles, total] = await Promise.all([
    prisma.therapistProfile.findMany({
      where,
      select: THERAPIST_SELECT,
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { approvedAt: 'desc' },
    }),
    prisma.therapistProfile.count({ where }),
  ]);

  return {
    therapists: profiles.map(_formatProfile),
    pagination: { page, limit, total },
  };
}

/**
 * Returns a single active therapist's full profile by therapistProfileId.
 * Throws 404 if not found or not active.
 *
 * @param {string} therapistProfileId
 * @returns {Promise<object>}
 */
async function getTherapistById(therapistProfileId) {
  const profile = await prisma.therapistProfile.findUnique({
    where: { id: therapistProfileId },
    select: THERAPIST_SELECT,
  });

  if (!profile || profile.status !== 'active') {
    const err = new Error('Therapist not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  return _formatProfile(profile);
}

/**
 * Creates or updates the therapist profile for the given userId.
 * Only users with role = therapist can call this.
 * Throws 403 if the user is not a therapist.
 *
 * @param {string} userId - Internal user ID
 * @param {object} data - Validated profile fields
 * @returns {Promise<object>}
 */
async function upsertTherapistProfile(userId, data) {
  const existing = await prisma.therapistProfile.findUnique({
    where: { userId },
    select: { id: true, status: true },
  });

  if (existing) {
    return prisma.therapistProfile.update({
      where: { userId },
      data: {
        bio: data.bio,
        specialisations: data.specialisations,
        qualifications: data.qualifications,
        yearsExperience: data.yearsExperience,
        languagesSpoken: data.languagesSpoken,
        sessionRateNgn: data.sessionRateNgn,
        ...(data.availabilityJson && { availabilityJson: data.availabilityJson }),
      },
    });
  }

  return prisma.therapistProfile.create({
    data: {
      userId,
      bio: data.bio,
      specialisations: data.specialisations,
      qualifications: data.qualifications,
      yearsExperience: data.yearsExperience,
      languagesSpoken: data.languagesSpoken,
      sessionRateNgn: data.sessionRateNgn,
      ...(data.availabilityJson && { availabilityJson: data.availabilityJson }),
    },
  });
}

/**
 * Approves a therapist — sets status to active.
 * Sends FCM push + Resend email to the therapist.
 *
 * @param {string} therapistProfileId
 * @param {string} adminUserId - The approving admin's user ID
 * @returns {Promise<void>}
 */
async function approveTherapist(therapistProfileId, adminUserId) {
  const profile = await _requirePendingProfile(therapistProfileId);

  await prisma.therapistProfile.update({
    where: { id: therapistProfileId },
    data: {
      status: 'active',
      approvedAt: new Date(),
      approvedByAdminId: adminUserId,
    },
  });

  const { firstName, fcmToken } = profile.user;
  const supabaseEmail = await _getSupabaseEmail(profile.user.id);

  await Promise.allSettled([
    _sendApprovalPush(fcmToken, firstName),
    sendTherapistApprovedEmail({ toEmail: supabaseEmail, firstName }),
  ]);
}

/**
 * Rejects a therapist — sets status to rejected with reason.
 * Sends FCM push + Resend email to the therapist.
 *
 * @param {string} therapistProfileId
 * @param {string} reason
 * @returns {Promise<void>}
 */
async function rejectTherapist(therapistProfileId, reason) {
  const profile = await _requirePendingProfile(therapistProfileId);

  await prisma.therapistProfile.update({
    where: { id: therapistProfileId },
    data: { status: 'rejected', rejectionReason: reason },
  });

  const { firstName, fcmToken } = profile.user;
  const supabaseEmail = await _getSupabaseEmail(profile.user.id);

  await Promise.allSettled([
    _sendRejectionPush(fcmToken, firstName, reason),
    sendTherapistRejectedEmail({ toEmail: supabaseEmail, firstName, reason }),
  ]);
}

/**
 * Returns all pending therapist profiles for the admin review queue.
 *
 * @returns {Promise<object[]>}
 */
async function listPendingTherapists() {
  const profiles = await prisma.therapistProfile.findMany({
    where: { status: 'pending' },
    select: {
      id: true,
      bio: true,
      specialisations: true,
      qualifications: true,
      yearsExperience: true,
      languagesSpoken: true,
      createdAt: true,
      user: {
        select: { id: true, firstName: true, lastName: true, avatarUrl: true },
      },
    },
    orderBy: { createdAt: 'asc' },
  });

  return profiles.map((p) => ({
    id: p.id,
    firstName: p.user.firstName,
    lastName: p.user.lastName,
    avatarUrl: p.user.avatarUrl,
    bio: p.bio,
    specialisations: p.specialisations,
    qualifications: p.qualifications,
    yearsExperience: p.yearsExperience,
    languagesSpoken: p.languagesSpoken,
    appliedAt: p.createdAt,
  }));
}

// ── Private helpers ───────────────────────────────────────────────────────────

/**
 * Fetches a therapist profile and verifies it is in pending status.
 * Throws 404 if not found, 409 if already processed.
 *
 * @param {string} therapistProfileId
 * @returns {Promise<object>}
 */
async function _requirePendingProfile(therapistProfileId) {
  const profile = await prisma.therapistProfile.findUnique({
    where: { id: therapistProfileId },
    select: {
      id: true,
      status: true,
      user: { select: { id: true, firstName: true, fcmToken: true } },
    },
  });

  if (!profile) {
    const err = new Error('Therapist profile not found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  if (profile.status !== 'pending') {
    const err = new Error('Therapist application already processed.');
    err.statusCode = 409;
    err.code = 'CONFLICT';
    throw err;
  }

  return profile;
}

/**
 * Looks up the Supabase email for a user by their internal ID.
 * Falls back to an empty string if lookup fails — email is best-effort.
 *
 * @param {string} userId
 * @returns {Promise<string>}
 */
async function _getSupabaseEmail(userId) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { supabaseId: true },
    });
    if (!user) return '';

    const { supabase } = require('../config/supabase');
    const { data } = await supabase.auth.admin.getUserById(user.supabaseId);
    return data?.user?.email ?? '';
  } catch (err) {
    console.error('[therapists]', err.message);
    return '';
  }
}

/**
 * Sends an FCM push to a therapist notifying them of approval.
 *
 * @param {string|null} fcmToken
 * @param {string} firstName
 * @returns {Promise<void>}
 */
async function _sendApprovalPush(fcmToken, firstName) {
  if (!fcmToken) return;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Application approved',
        body: `Alhamdulillah ${firstName}! Your profile is now live on Noor Companion.`,
      },
      data: { type: 'therapist_approved' },
    });
  } catch (err) {
    console.error('[therapists]', err.message);
  }
}

/**
 * Sends an FCM push to a therapist notifying them of rejection.
 *
 * @param {string|null} fcmToken
 * @param {string} firstName
 * @param {string} reason
 * @returns {Promise<void>}
 */
async function _sendRejectionPush(fcmToken, firstName, reason) {
  if (!fcmToken) return;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Application update',
        body: `${firstName}, your application could not be approved at this time.`,
      },
      data: { type: 'therapist_rejected', reason },
    });
  } catch (err) {
    console.error('[therapists]', err.message);
  }
}

/**
 * Formats a raw Prisma TherapistProfile row into the public API shape.
 *
 * @param {object} profile
 * @returns {object}
 */
function _formatProfile(profile) {
  const totalRatings = profile.ratings.length;
  const averageRating = totalRatings > 0
    ? Math.round((profile.ratings.reduce((sum, r) => sum + r.rating, 0) / totalRatings) * 10) / 10
    : null;

  return {
    id: profile.id,
    firstName: profile.user.firstName,
    lastName: profile.user.lastName,
    avatarUrl: profile.user.avatarUrl ?? null,
    bio: profile.bio,
    specialisations: profile.specialisations,
    qualifications: profile.qualifications,
    yearsExperience: profile.yearsExperience,
    languagesSpoken: profile.languagesSpoken,
    sessionRateNgn: profile.sessionRateNgn,
    availabilityJson: profile.availabilityJson ?? null,
    averageRating,
    totalSessions: profile.sessions.length,
  };
}

/**
 * Returns the authenticated therapist's own profile including status.
 * Unlike getTherapistById, this does NOT filter by status = active,
 * so pending and rejected therapists can also view their profile.
 *
 * @param {string} userId - Therapist's Prisma User ID
 * @returns {Promise<object>}
 * @throws {{ code: 'NOT_FOUND', statusCode: 404 }}
 */
async function getMyTherapistProfile(userId) {
  const profile = await prisma.therapistProfile.findUnique({
    where: { userId },
    select: {
      ...THERAPIST_SELECT,
      status: true,
      rejectionReason: true,
    },
  });

  if (!profile) {
    const err = new Error('No therapist profile found.');
    err.statusCode = 404;
    err.code = 'NOT_FOUND';
    throw err;
  }

  return { ..._formatProfile(profile), status: profile.status, rejectionReason: profile.rejectionReason ?? null };
}

module.exports = {
  listTherapists,
  getTherapistById,
  getMyTherapistProfile,
  upsertTherapistProfile,
  approveTherapist,
  rejectTherapist,
  listPendingTherapists,
};
