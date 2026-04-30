'use strict';

jest.mock('../config/prisma', () => ({
  prisma: {
    content: { findMany: jest.fn(), findUnique: jest.fn() },
    contentProgress: { upsert: jest.fn() },
    streak: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
  },
}));

jest.mock('../config/redis', () => ({
  redis: { get: jest.fn(), setex: jest.fn() },
}));

jest.mock('../services/streak.service', () => ({
  updateStreak: jest.fn().mockResolvedValue({ currentStreak: 1, longestStreak: 1 }),
}));

const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');
const { listContent, recordProgress } = require('../services/content.service');

beforeEach(() => jest.clearAllMocks());

describe('listContent', () => {
  const mockItems = [
    { id: 'c1', title: 'SubhanAllah', arabicText: 'سبحان الله', transliteration: 'SubhanAllah', translation: 'Glory be to Allah', audioUrl: null, tags: ['morning'], sortOrder: 1 },
  ];

  it('returns cached data when cache hit', async () => {
    redis.get.mockResolvedValue(JSON.stringify(mockItems));
    const result = await listContent('dhikr');
    expect(redis.get).toHaveBeenCalledWith('content:dhikr:all');
    expect(prisma.content.findMany).not.toHaveBeenCalled();
    expect(result).toEqual(mockItems);
  });

  it('fetches from DB and caches on cache miss', async () => {
    redis.get.mockResolvedValue(null);
    prisma.content.findMany.mockResolvedValue(mockItems);
    const result = await listContent('dhikr');
    expect(prisma.content.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ category: 'dhikr', isActive: true }) })
    );
    expect(redis.setex).toHaveBeenCalledWith('content:dhikr:all', 86400, JSON.stringify(mockItems));
    expect(result).toEqual(mockItems);
  });

  it('uses tag-specific cache key when tag provided', async () => {
    redis.get.mockResolvedValue(null);
    prisma.content.findMany.mockResolvedValue([]);
    await listContent('dhikr', 'morning');
    expect(redis.get).toHaveBeenCalledWith('content:dhikr:tag:morning');
  });

  it('filters by tag in DB query when tag provided', async () => {
    redis.get.mockResolvedValue(null);
    prisma.content.findMany.mockResolvedValue([]);
    await listContent('dua', 'evening');
    expect(prisma.content.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ tags: { has: 'evening' } }) })
    );
  });
});

describe('recordProgress', () => {
  it('records progress and returns streak', async () => {
    prisma.content.findUnique.mockResolvedValue({ id: 'c1', isActive: true });
    prisma.contentProgress.upsert.mockResolvedValue({});
    const result = await recordProgress('user-1', 'c1');
    expect(prisma.contentProgress.upsert).toHaveBeenCalled();
    expect(result).toHaveProperty('streak');
    expect(result.message).toBe('Progress recorded.');
  });

  it('throws 404 when content not found', async () => {
    prisma.content.findUnique.mockResolvedValue(null);
    await expect(recordProgress('user-1', 'bad-id')).rejects.toMatchObject({ statusCode: 404, code: 'NOT_FOUND' });
  });

  it('throws 404 when content is inactive', async () => {
    prisma.content.findUnique.mockResolvedValue({ id: 'c1', isActive: false });
    await expect(recordProgress('user-1', 'c1')).rejects.toMatchObject({ statusCode: 404 });
  });
});
