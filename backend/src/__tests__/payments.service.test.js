'use strict';

jest.mock('../config/env', () => ({
  env: {
    SUBSCRIPTION_TOKEN_SECRET: 'x'.repeat(32),
    WEBSITE_URL: 'https://noorcompanion.netlify.app',
    PAYSTACK_SECRET_KEY: 'sk_test_x',
    RESEND_API_KEY: 're_x',
    FROM_EMAIL: 'noreply@noorcompanion.com',
  },
}));

jest.mock('../config/prisma', () => ({
  prisma: {
    paymentEvent: { findUnique: jest.fn(), create: jest.fn() },
    user: { update: jest.fn() },
    $transaction: jest.fn(),
  },
}));

jest.mock('../services/notification.service', () => ({
  notificationService: { sendToUser: jest.fn().mockResolvedValue(undefined) },
}));

const { prisma } = require('../config/prisma');
const { processSuccessfulPayment } = require('../services/payments.service');

beforeEach(() => jest.clearAllMocks());

const charge = (overrides = {}) => ({
  id: 12345,
  metadata: { userId: 'cuid-1' },
  amount: 500000,
  currency: 'NGN',
  ...overrides,
});

describe('processSuccessfulPayment', () => {
  it('grants the paid tier for the exact plan price', async () => {
    prisma.paymentEvent.findUnique.mockResolvedValue(null);
    prisma.$transaction.mockResolvedValue([]);

    await processSuccessfulPayment(charge());

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { subscriptionTier: 'paid' } }),
    );
  });

  it('ignores charges that do not match the plan price', async () => {
    await processSuccessfulPayment(charge({ amount: 100 })); // ₦1 — never grant tier

    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.user.update).not.toHaveBeenCalled();
  });

  it('ignores non-NGN charges', async () => {
    await processSuccessfulPayment(charge({ currency: 'USD' }));

    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('ignores events without a userId in metadata', async () => {
    await processSuccessfulPayment(charge({ metadata: {} }));

    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('skips duplicate events (idempotent)', async () => {
    prisma.paymentEvent.findUnique.mockResolvedValue({ id: 'existing' });

    await processSuccessfulPayment(charge());

    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
