'use strict';

jest.mock('agora-token', () => ({
  RtcTokenBuilder: {
    buildTokenWithUid: jest.fn().mockReturnValue('mock-rtc-token'),
  },
  RtcRole: { PUBLISHER: 1 },
}));

const { RtcTokenBuilder } = require('agora-token');
const { generateRtcToken } = require('../utils/agora');

beforeEach(() => {
  process.env.AGORA_APP_ID = 'test-app-id';
  process.env.AGORA_APP_CERTIFICATE = 'test-certificate';
  jest.clearAllMocks();
});

describe('generateRtcToken', () => {
  it('calls RtcTokenBuilder with correct app credentials', () => {
    generateRtcToken('noor_test_channel');
    expect(RtcTokenBuilder.buildTokenWithUid).toHaveBeenCalledWith(
      'test-app-id',
      'test-certificate',
      'noor_test_channel',
      0,
      1,
      expect.any(Number),
      expect.any(Number),
    );
  });

  it('returns the token from RtcTokenBuilder', () => {
    const token = generateRtcToken('noor_test_channel');
    expect(token).toBe('mock-rtc-token');
  });

  it('sets expiry time ~1 hour in the future', () => {
    generateRtcToken('noor_test_channel');
    const call = RtcTokenBuilder.buildTokenWithUid.mock.calls[0];
    const expiryTime = call[5];
    const now = Math.floor(Date.now() / 1000);
    expect(expiryTime).toBeGreaterThanOrEqual(now + 3590);
    expect(expiryTime).toBeLessThanOrEqual(now + 3610);
  });
});
