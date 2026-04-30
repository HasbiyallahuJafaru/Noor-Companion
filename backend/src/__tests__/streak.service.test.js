'use strict';

jest.mock('../config/prisma', () => ({
  prisma: {
    streak: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
    },
  },
}));

const { prisma } = require('../config/prisma');
const { getUserStreak, updateStreak, findStreakRiskUsers } = require('../services/streak.service');

beforeEach(() => jest.clearAllMocks());

describe('getUserStreak', () => {
  it('returns zero state when no streak record exists', async () => {
    prisma.streak.findUnique.mockResolvedValue(null);
    const result = await getUserStreak('user-1');
    expect(result).toEqual({ currentStreak: 0, longestStreak: 0, totalDays: 0, lastEngagedAt: null });
  });

  it('returns existing streak data', async () => {
    const mockStreak = { currentStreak: 5, longestStreak: 10, totalDays: 20, lastEngagedAt: new Date() };
    prisma.streak.findUnique.mockResolvedValue(mockStreak);
    const result = await getUserStreak('user-1');
    expect(result.currentStreak).toBe(5);
    expect(result.longestStreak).toBe(10);
  });
});

describe('updateStreak', () => {
  it('creates new streak record on first engagement', async () => {
    prisma.streak.findUnique.mockResolvedValue(null);
    prisma.streak.create.mockResolvedValue({ currentStreak: 1, longestStreak: 1, totalDays: 1 });
    const result = await updateStreak('user-1');
    expect(prisma.streak.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ currentStreak: 1, longestStreak: 1, totalDays: 1 }) })
    );
    expect(result.currentStreak).toBe(1);
  });

  it('returns existing streak unchanged when engaged today', async () => {
    const todayUTC = new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), new Date().getUTCDate()));
    const mockStreak = { currentStreak: 3, longestStreak: 5, totalDays: 10, lastEngagedAt: todayUTC };
    prisma.streak.findUnique.mockResolvedValue(mockStreak);
    const result = await updateStreak('user-1');
    expect(prisma.streak.update).not.toHaveBeenCalled();
    expect(result.currentStreak).toBe(3);
  });

  it('increments streak on consecutive day engagement', async () => {
    const yesterday = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const yesterdayUTC = new Date(Date.UTC(yesterday.getUTCFullYear(), yesterday.getUTCMonth(), yesterday.getUTCDate()));
    prisma.streak.findUnique.mockResolvedValue({ currentStreak: 4, longestStreak: 7, totalDays: 15, lastEngagedAt: yesterdayUTC });
    prisma.streak.update.mockResolvedValue({ currentStreak: 5, longestStreak: 7, totalDays: 16 });
    await updateStreak('user-1');
    expect(prisma.streak.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ currentStreak: 5 }) })
    );
  });

  it('resets streak to 1 after a gap', async () => {
    const threeDaysAgo = new Date();
    threeDaysAgo.setUTCDate(threeDaysAgo.getUTCDate() - 3);
    const gapDate = new Date(Date.UTC(threeDaysAgo.getUTCFullYear(), threeDaysAgo.getUTCMonth(), threeDaysAgo.getUTCDate()));
    prisma.streak.findUnique.mockResolvedValue({ currentStreak: 10, longestStreak: 10, totalDays: 30, lastEngagedAt: gapDate });
    prisma.streak.update.mockResolvedValue({ currentStreak: 1, longestStreak: 10, totalDays: 31 });
    await updateStreak('user-1');
    expect(prisma.streak.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ currentStreak: 1 }) })
    );
  });

  it('updates longestStreak when current exceeds it', async () => {
    const yesterday = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const yesterdayUTC = new Date(Date.UTC(yesterday.getUTCFullYear(), yesterday.getUTCMonth(), yesterday.getUTCDate()));
    prisma.streak.findUnique.mockResolvedValue({ currentStreak: 9, longestStreak: 9, totalDays: 25, lastEngagedAt: yesterdayUTC });
    prisma.streak.update.mockResolvedValue({ currentStreak: 10, longestStreak: 10, totalDays: 26 });
    await updateStreak('user-1');
    expect(prisma.streak.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ currentStreak: 10, longestStreak: 10 }) })
    );
  });
});

describe('findStreakRiskUsers', () => {
  it('returns only active users with FCM tokens who have not engaged today', async () => {
    const yesterday = new Date();
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    prisma.streak.findMany.mockResolvedValue([
      { currentStreak: 5, user: { id: 'u1', fcmToken: 'token-1', isActive: true } },
      { currentStreak: 3, user: { id: 'u2', fcmToken: null, isActive: true } },
      { currentStreak: 2, user: { id: 'u3', fcmToken: 'token-3', isActive: false } },
    ]);
    const result = await findStreakRiskUsers();
    expect(result).toHaveLength(1);
    expect(result[0].userId).toBe('u1');
    expect(result[0].fcmToken).toBe('token-1');
  });

  it('returns empty array when no at-risk users', async () => {
    prisma.streak.findMany.mockResolvedValue([]);
    const result = await findStreakRiskUsers();
    expect(result).toEqual([]);
  });
});
