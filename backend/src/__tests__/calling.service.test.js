'use strict';

jest.mock('@paralleldrive/cuid2', () => ({ createId: () => 'mock-cuid' }));

jest.mock('../config/env', () => ({
  env: {
    AGORA_APP_ID: 'test-app-id',
    AGORA_APP_CERTIFICATE: 'test-cert',
    UPSTASH_REDIS_URL: 'redis://localhost:6379',
  },
}));

jest.mock('../config/redis', () => ({
  redis: { get: jest.fn(), setex: jest.fn(), del: jest.fn() },
}));

jest.mock('../workers/callTimeout.worker', () => ({
  callTimeoutQueue: { add: jest.fn().mockResolvedValue({}) },
}));

jest.mock('../config/prisma', () => ({
  prisma: {
    user: { findUnique: jest.fn() },
    therapistProfile: { findUnique: jest.fn() },
    callSession: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn(), findMany: jest.fn(), count: jest.fn() },
    sessionRating: { create: jest.fn() },
  },
}));

jest.mock('../utils/agora', () => ({
  generateRtcToken: jest.fn().mockReturnValue('mock-agora-token'),
}));

jest.mock('../services/notification.service', () => ({
  sendPushNotification: jest.fn().mockResolvedValue(true),
}));

const { prisma } = require('../config/prisma');
const { initiateCall, endCall, rateSession } = require('../services/calling.service');

beforeEach(() => jest.clearAllMocks());

const mockUser = { id: 'user-1', subscriptionTier: 'paid', firstName: 'Ahmad', avatarUrl: null };
const mockTherapist = { id: 'tp-1', userId: 'therapist-user-1', status: 'active', user: { id: 'therapist-user-1', fcmToken: 'fcm-token' } };
const mockSession = { id: 'session-1', agoraChannelName: 'noor_abc', status: 'active', startedAt: new Date(), userId: 'user-1', therapistProfileId: 'tp-1' };

describe('initiateCall', () => {
  it('creates a session for a paid user with an active therapist', async () => {
    prisma.user.findUnique.mockResolvedValue(mockUser);
    prisma.therapistProfile.findUnique.mockResolvedValue(mockTherapist);
    prisma.callSession.create.mockResolvedValue({ ...mockSession, status: 'initiated' });
    const result = await initiateCall('user-1', 'tp-1');
    expect(prisma.callSession.create).toHaveBeenCalled();
    expect(result).toHaveProperty('agoraToken', 'mock-agora-token');
    expect(result).toHaveProperty('sessionId');
  });

  it('throws PAYMENT_REQUIRED for free tier users', async () => {
    prisma.user.findUnique.mockResolvedValue({ ...mockUser, subscriptionTier: 'free' });
    await expect(initiateCall('user-1', 'tp-1')).rejects.toMatchObject({ code: 'SUBSCRIPTION_REQUIRED' });
  });

  it('throws NOT_FOUND when therapist does not exist', async () => {
    prisma.user.findUnique.mockResolvedValue(mockUser);
    prisma.therapistProfile.findUnique.mockResolvedValue(null);
    await expect(initiateCall('user-1', 'tp-1')).rejects.toMatchObject({ statusCode: 404 });
  });

  it('throws NOT_FOUND when therapist is not active (filtered out by status query)', async () => {
    prisma.user.findUnique.mockResolvedValue(mockUser);
    prisma.therapistProfile.findUnique.mockResolvedValue(null);
    await expect(initiateCall('user-1', 'tp-1')).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('endCall', () => {
  it('marks session as completed and calculates duration', async () => {
    const startedAt = new Date(Date.now() - 300_000); // 5 min ago
    prisma.callSession.findUnique.mockResolvedValue({ ...mockSession, startedAt, status: 'active' });
    prisma.callSession.update.mockResolvedValue({ ...mockSession, status: 'completed', durationSeconds: 300 });
    const result = await endCall('session-1');
    expect(prisma.callSession.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'completed' }) })
    );
    expect(result).toHaveProperty('durationSeconds');
  });

  it('throws NOT_FOUND when session does not exist', async () => {
    prisma.callSession.findUnique.mockResolvedValue(null);
    await expect(endCall('bad-id')).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('rateSession', () => {
  it('creates a rating and returns success message', async () => {
    prisma.callSession.findUnique.mockResolvedValue({ ...mockSession, status: 'completed', therapistProfileId: 'tp-1', rating: null });
    prisma.sessionRating.create.mockResolvedValue({ id: 'rating-1', rating: 5 });
    const result = await rateSession('user-1', 'session-1', 5, 'Great!');
    expect(prisma.sessionRating.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ rating: 5, userId: 'user-1' }) })
    );
    expect(result).toEqual({ message: 'Rating submitted.' });
  });

  it('returns early if session already rated', async () => {
    prisma.callSession.findUnique.mockResolvedValue({ ...mockSession, rating: { id: 'existing' } });
    const result = await rateSession('user-1', 'session-1', 4);
    expect(prisma.sessionRating.create).not.toHaveBeenCalled();
    expect(result).toEqual({ message: 'Rating submitted.' });
  });

  it('throws FORBIDDEN when user did not own the session', async () => {
    prisma.callSession.findUnique.mockResolvedValue({ ...mockSession, userId: 'other-user', rating: null });
    await expect(rateSession('user-1', 'session-1', 4)).rejects.toMatchObject({ code: 'FORBIDDEN' });
  });

  it('throws NOT_FOUND when session does not exist', async () => {
    prisma.callSession.findUnique.mockResolvedValue(null);
    await expect(rateSession('user-1', 'bad-id', 4)).rejects.toMatchObject({ statusCode: 404 });
  });
});
