'use strict';

const { initiateCallSchema, rateCallSchema } = require('../validators/calls.validator');
const { updateProfileSchema, fcmTokenSchema } = require('../validators/users.validator');
const { createContentSchema } = require('../validators/content.validator');
const { therapistProfileSchema } = require('../validators/therapists.validator');

describe('initiateCallSchema', () => {
  it('passes with valid therapistProfileId', () => {
    const result = initiateCallSchema.safeParse({ therapistProfileId: 'abc123' });
    expect(result.success).toBe(true);
  });

  it('fails with missing therapistProfileId', () => {
    const result = initiateCallSchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it('fails with empty string therapistProfileId', () => {
    const result = initiateCallSchema.safeParse({ therapistProfileId: '' });
    expect(result.success).toBe(false);
  });
});

describe('rateCallSchema', () => {
  it('passes with valid rating', () => {
    expect(rateCallSchema.safeParse({ rating: 5 }).success).toBe(true);
    expect(rateCallSchema.safeParse({ rating: 1 }).success).toBe(true);
  });

  it('passes with optional comment', () => {
    expect(rateCallSchema.safeParse({ rating: 4, comment: 'Great session' }).success).toBe(true);
  });

  it('fails with rating out of range', () => {
    expect(rateCallSchema.safeParse({ rating: 0 }).success).toBe(false);
    expect(rateCallSchema.safeParse({ rating: 6 }).success).toBe(false);
  });

  it('fails with non-integer rating', () => {
    expect(rateCallSchema.safeParse({ rating: 3.5 }).success).toBe(false);
  });

  it('fails with comment over 500 chars', () => {
    expect(rateCallSchema.safeParse({ rating: 3, comment: 'x'.repeat(501) }).success).toBe(false);
  });
});

describe('updateProfileSchema', () => {
  it('passes with valid firstName', () => {
    expect(updateProfileSchema.safeParse({ firstName: 'Ahmad' }).success).toBe(true);
  });

  it('passes with valid avatarUrl', () => {
    expect(updateProfileSchema.safeParse({ avatarUrl: 'https://example.com/avatar.png' }).success).toBe(true);
  });

  it('passes with null avatarUrl', () => {
    expect(updateProfileSchema.safeParse({ avatarUrl: null }).success).toBe(true);
  });

  it('fails with empty object', () => {
    expect(updateProfileSchema.safeParse({}).success).toBe(false);
  });

  it('fails with invalid avatarUrl', () => {
    expect(updateProfileSchema.safeParse({ avatarUrl: 'not-a-url' }).success).toBe(false);
  });

  it('fails with firstName over 100 chars', () => {
    expect(updateProfileSchema.safeParse({ firstName: 'a'.repeat(101) }).success).toBe(false);
  });
});

describe('fcmTokenSchema', () => {
  it('passes with valid token', () => {
    expect(fcmTokenSchema.safeParse({ fcmToken: 'abc:xyz123' }).success).toBe(true);
  });

  it('fails with empty token', () => {
    expect(fcmTokenSchema.safeParse({ fcmToken: '' }).success).toBe(false);
  });

  it('fails with missing token', () => {
    expect(fcmTokenSchema.safeParse({}).success).toBe(false);
  });
});
