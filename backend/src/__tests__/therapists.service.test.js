'use strict';

jest.mock('../config/firebase', () => ({ admin: { messaging: () => ({ send: jest.fn() }) } }));
jest.mock('../utils/email', () => ({
  sendTherapistApprovedEmail: jest.fn(),
  sendTherapistRejectedEmail: jest.fn(),
}));
jest.mock('../config/prisma', () => ({
  prisma: {
    therapistProfile: { findMany: jest.fn(), findUnique: jest.fn(), count: jest.fn() },
    sessionRating: { groupBy: jest.fn() },
    callSession: { groupBy: jest.fn() },
  },
}));

const { prisma } = require('../config/prisma');
const { listTherapists, getTherapistById } = require('../services/therapists.service');

beforeEach(() => jest.clearAllMocks());

const mockProfile = {
  id: 'tp-1',
  status: 'active',
  bio: 'Experienced counsellor',
  specialisations: ['addiction'],
  qualifications: ['BSc'],
  yearsExperience: 5,
  languagesSpoken: ['English'],
  sessionRateNgn: 5000,
  availabilityJson: null,
  approvedAt: new Date(),
  user: { id: 'u1', firstName: 'Fatima', lastName: 'Bello', avatarUrl: null, fcmToken: null },
};

describe('therapist aggregates', () => {
  it('computes averageRating and totalSessions via groupBy, not row loads', async () => {
    prisma.therapistProfile.findMany.mockResolvedValue([mockProfile]);
    prisma.therapistProfile.count.mockResolvedValue(1);
    prisma.sessionRating.groupBy.mockResolvedValue([
      { therapistProfileId: 'tp-1', _avg: { rating: 4.3333 } },
    ]);
    prisma.callSession.groupBy.mockResolvedValue([
      { therapistProfileId: 'tp-1', _count: { _all: 12 } },
    ]);

    const { therapists } = await listTherapists({ page: 1, limit: 20 });

    expect(prisma.sessionRating.groupBy).toHaveBeenCalledTimes(1);
    expect(prisma.callSession.groupBy).toHaveBeenCalledTimes(1);
    expect(therapists[0].averageRating).toBe(4.3);
    expect(therapists[0].totalSessions).toBe(12);
  });

  it('returns null rating and 0 sessions for a therapist with no history', async () => {
    prisma.therapistProfile.findUnique.mockResolvedValue(mockProfile);
    prisma.sessionRating.groupBy.mockResolvedValue([]);
    prisma.callSession.groupBy.mockResolvedValue([]);

    const therapist = await getTherapistById('tp-1');

    expect(therapist.averageRating).toBeNull();
    expect(therapist.totalSessions).toBe(0);
  });

  it('handles an empty directory without calling groupBy', async () => {
    prisma.therapistProfile.findMany.mockResolvedValue([]);
    prisma.therapistProfile.count.mockResolvedValue(0);

    const { therapists } = await listTherapists({ page: 1, limit: 20 });

    expect(therapists).toEqual([]);
    expect(prisma.sessionRating.groupBy).not.toHaveBeenCalled();
    expect(prisma.callSession.groupBy).not.toHaveBeenCalled();
  });
});
