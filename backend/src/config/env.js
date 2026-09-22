/**
 * Validated environment configuration.
 * Server refuses to start if any required variable is missing or malformed.
 */

'use strict';

const { z } = require('zod');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().min(1),
  DIRECT_DATABASE_URL: z.string().min(1),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  // Optional — enables local HS256 JWT verification in auth middleware
  // (skips a Supabase network roundtrip on every request). Legacy project
  // JWT secret from Supabase → Settings → API.
  SUPABASE_JWT_SECRET: z.string().default(''),
  SENTRY_DSN: z.string().default(''),
  SUBSCRIPTION_TOKEN_SECRET: z.string().min(32),
  UPSTASH_REDIS_URL: z.string().min(1),
  PAYSTACK_SECRET_KEY: z.string().min(1),
  AGORA_APP_ID: z.string().min(1),
  AGORA_APP_CERTIFICATE: z.string().default(''),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIREBASE_PRIVATE_KEY: z.string().min(1),
  FIREBASE_CLIENT_EMAIL: z.string().email(),
  RESEND_API_KEY: z.string().default(''),
  FROM_EMAIL: z.string().default('noreply@noorcompanion.com'),
  WEBSITE_URL: z.string().default('https://noorcompanion.netlify.app'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌  Invalid environment variables:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

module.exports = { env: parsed.data };
