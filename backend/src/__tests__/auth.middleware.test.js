'use strict';

process.env.SUPABASE_JWT_SECRET = 'test-secret-at-least-32-chars-long!!';

jest.mock('../config/supabase', () => ({
  supabase: {
    auth: {
      getUser: jest.fn().mockResolvedValue({
        data: { user: null },
        error: { message: 'invalid claim: missing sub claim' },
      }),
    },
  },
}));

jest.mock('../config/prisma', () => ({
  prisma: {
    user: { upsert: jest.fn() },
  },
}));

const jwt = require('jsonwebtoken');
const { authenticate } = require('../middleware/auth');
const { supabase } = require('../config/supabase');
const { prisma } = require('../config/prisma');

beforeEach(() => jest.clearAllMocks());

const appUser = {
  id: 'cuid-1',
  supabaseId: 'supa-1',
  firstName: 'Ahmad',
  lastName: '',
  role: 'user',
  subscriptionTier: 'free',
  isActive: true,
  fcmToken: null,
};

function run(token) {
  const req = { headers: { authorization: `Bearer ${token}` } };
  const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
  const next = jest.fn();
  return authenticate(req, res, next).then(() => ({ req, res, next }));
}

describe('authenticate', () => {
  it('verifies a valid HS256 token locally — no Supabase roundtrip, no prisma hit on second call', async () => {
    prisma.user.upsert.mockResolvedValue(appUser);
    const token = jwt.sign(
      { sub: 'supa-1', email: 'a@b.com', user_metadata: { first_name: 'Ahmad' } },
      process.env.SUPABASE_JWT_SECRET,
    );

    const first = await run(token);
    expect(first.next).toHaveBeenCalled();
    expect(first.req.user.id).toBe('cuid-1');
    expect(first.req.user.email).toBe('a@b.com');

    const second = await run(token);
    expect(second.next).toHaveBeenCalled();
    expect(prisma.user.upsert).toHaveBeenCalledTimes(1); // second served from cache
    expect(supabase.auth.getUser).not.toHaveBeenCalled();
  });

  it('falls back to remote verification when local verify fails', async () => {
    const token = jwt.sign({ sub: 'supa-1' }, 'wrong-secret');
    await run(token);
    expect(supabase.auth.getUser).toHaveBeenCalledWith(token);
  });

  it('rejects a suspended user with 401', async () => {
    prisma.user.upsert.mockResolvedValue({ ...appUser, id: 'cuid-suspended', supabaseId: 'supa-suspended', isActive: false });
    const token = jwt.sign({ sub: 'supa-suspended', email: 'a@b.com' }, process.env.SUPABASE_JWT_SECRET);

    const { res, next } = await run(token);
    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(401);
  });
});
