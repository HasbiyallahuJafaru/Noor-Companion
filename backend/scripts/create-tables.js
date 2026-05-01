'use strict';

require('dotenv').config();
const { Client } = require('pg');

const sql = `
-- Enums
DO $$ BEGIN
  CREATE TYPE "Role" AS ENUM ('user', 'therapist', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "SubscriptionTier" AS ENUM ('free', 'paid');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "TherapistStatus" AS ENUM ('pending', 'active', 'rejected', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "SessionStatus" AS ENUM ('initiated', 'active', 'completed', 'missed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "NotificationType" AS ENUM ('streak_reminder', 'session_incoming', 'session_completed', 'subscription_active', 'therapist_approved', 'therapist_rejected', 'general');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE "ContentCategory" AS ENUM ('dhikr', 'dua', 'recitation');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- User
CREATE TABLE IF NOT EXISTS "User" (
  "id"               TEXT NOT NULL,
  "supabaseId"       TEXT NOT NULL,
  "firstName"        TEXT NOT NULL,
  "lastName"         TEXT NOT NULL,
  "role"             "Role" NOT NULL DEFAULT 'user',
  "subscriptionTier" "SubscriptionTier" NOT NULL DEFAULT 'free',
  "avatarUrl"        TEXT,
  "fcmToken"         TEXT,
  "isActive"         BOOLEAN NOT NULL DEFAULT true,
  "lastSeenAt"       TIMESTAMP(3),
  "createdAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "User_supabaseId_key" ON "User"("supabaseId");
CREATE INDEX IF NOT EXISTS "User_supabaseId_idx" ON "User"("supabaseId");

-- TherapistProfile
CREATE TABLE IF NOT EXISTS "TherapistProfile" (
  "id"                TEXT NOT NULL,
  "userId"            TEXT NOT NULL,
  "status"            "TherapistStatus" NOT NULL DEFAULT 'pending',
  "bio"               TEXT NOT NULL,
  "specialisations"   TEXT[] NOT NULL DEFAULT '{}',
  "qualifications"    TEXT[] NOT NULL DEFAULT '{}',
  "yearsExperience"   INTEGER NOT NULL,
  "languagesSpoken"   TEXT[] NOT NULL DEFAULT '{}',
  "sessionRateNgn"    INTEGER NOT NULL,
  "availabilityJson"  JSONB,
  "approvedAt"        TIMESTAMP(3),
  "approvedByAdminId" TEXT,
  "rejectionReason"   TEXT,
  "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "TherapistProfile_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "TherapistProfile_userId_key" ON "TherapistProfile"("userId");
CREATE INDEX IF NOT EXISTS "TherapistProfile_status_idx" ON "TherapistProfile"("status");
DO $$ BEGIN
  ALTER TABLE "TherapistProfile" ADD CONSTRAINT "TherapistProfile_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- CallSession
CREATE TABLE IF NOT EXISTS "CallSession" (
  "id"                 TEXT NOT NULL,
  "userId"             TEXT NOT NULL,
  "therapistProfileId" TEXT NOT NULL,
  "agoraChannelName"   TEXT NOT NULL,
  "status"             "SessionStatus" NOT NULL DEFAULT 'initiated',
  "startedAt"          TIMESTAMP(3),
  "endedAt"            TIMESTAMP(3),
  "durationSeconds"    INTEGER,
  "createdAt"          TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CallSession_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "CallSession_agoraChannelName_key" ON "CallSession"("agoraChannelName");
CREATE INDEX IF NOT EXISTS "CallSession_userId_idx" ON "CallSession"("userId");
CREATE INDEX IF NOT EXISTS "CallSession_therapistProfileId_idx" ON "CallSession"("therapistProfileId");
DO $$ BEGIN
  ALTER TABLE "CallSession" ADD CONSTRAINT "CallSession_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "CallSession" ADD CONSTRAINT "CallSession_therapistProfileId_fkey"
    FOREIGN KEY ("therapistProfileId") REFERENCES "TherapistProfile"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- SessionRating
CREATE TABLE IF NOT EXISTS "SessionRating" (
  "id"                 TEXT NOT NULL,
  "sessionId"          TEXT NOT NULL,
  "userId"             TEXT NOT NULL,
  "therapistProfileId" TEXT NOT NULL,
  "rating"             INTEGER NOT NULL,
  "comment"            TEXT,
  "createdAt"          TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SessionRating_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "SessionRating_sessionId_key" ON "SessionRating"("sessionId");
DO $$ BEGIN
  ALTER TABLE "SessionRating" ADD CONSTRAINT "SessionRating_sessionId_fkey"
    FOREIGN KEY ("sessionId") REFERENCES "CallSession"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "SessionRating" ADD CONSTRAINT "SessionRating_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "SessionRating" ADD CONSTRAINT "SessionRating_therapistProfileId_fkey"
    FOREIGN KEY ("therapistProfileId") REFERENCES "TherapistProfile"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Streak
CREATE TABLE IF NOT EXISTS "Streak" (
  "id"            TEXT NOT NULL,
  "userId"        TEXT NOT NULL,
  "currentStreak" INTEGER NOT NULL DEFAULT 0,
  "longestStreak" INTEGER NOT NULL DEFAULT 0,
  "lastEngagedAt" TIMESTAMP(3),
  "totalDays"     INTEGER NOT NULL DEFAULT 0,
  "updatedAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Streak_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Streak_userId_key" ON "Streak"("userId");
DO $$ BEGIN
  ALTER TABLE "Streak" ADD CONSTRAINT "Streak_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Content
CREATE TABLE IF NOT EXISTS "Content" (
  "id"              TEXT NOT NULL,
  "title"           TEXT NOT NULL,
  "arabicText"      TEXT,
  "transliteration" TEXT,
  "translation"     TEXT,
  "audioUrl"        TEXT,
  "category"        "ContentCategory" NOT NULL,
  "tags"            TEXT[] NOT NULL DEFAULT '{}',
  "isActive"        BOOLEAN NOT NULL DEFAULT true,
  "sortOrder"       INTEGER NOT NULL DEFAULT 0,
  "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Content_pkey" PRIMARY KEY ("id")
);

-- ContentProgress
CREATE TABLE IF NOT EXISTS "ContentProgress" (
  "id"        TEXT NOT NULL,
  "userId"    TEXT NOT NULL,
  "contentId" TEXT NOT NULL,
  "engagedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ContentProgress_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "ContentProgress_userId_contentId_key" ON "ContentProgress"("userId", "contentId");
CREATE INDEX IF NOT EXISTS "ContentProgress_userId_idx" ON "ContentProgress"("userId");
DO $$ BEGIN
  ALTER TABLE "ContentProgress" ADD CONSTRAINT "ContentProgress_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "ContentProgress" ADD CONSTRAINT "ContentProgress_contentId_fkey"
    FOREIGN KEY ("contentId") REFERENCES "Content"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Notification
CREATE TABLE IF NOT EXISTS "Notification" (
  "id"        TEXT NOT NULL,
  "userId"    TEXT NOT NULL,
  "type"      "NotificationType" NOT NULL,
  "title"     TEXT NOT NULL,
  "body"      TEXT NOT NULL,
  "isRead"    BOOLEAN NOT NULL DEFAULT false,
  "data"      JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "Notification_userId_isRead_idx" ON "Notification"("userId", "isRead");
DO $$ BEGIN
  ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- PaymentEvent
CREATE TABLE IF NOT EXISTS "PaymentEvent" (
  "id"              TEXT NOT NULL,
  "paystackEventId" TEXT NOT NULL,
  "userId"          TEXT,
  "event"           TEXT NOT NULL,
  "amount"          INTEGER NOT NULL,
  "currency"        TEXT NOT NULL DEFAULT 'NGN',
  "status"          TEXT NOT NULL,
  "rawPayload"      JSONB NOT NULL,
  "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PaymentEvent_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "PaymentEvent_paystackEventId_key" ON "PaymentEvent"("paystackEventId");
DO $$ BEGIN
  ALTER TABLE "PaymentEvent" ADD CONSTRAINT "PaymentEvent_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id");
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Prisma migrations tracking table
CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
  "id"                  VARCHAR(36) NOT NULL,
  "checksum"            VARCHAR(64) NOT NULL,
  "finished_at"         TIMESTAMPTZ,
  "migration_name"      VARCHAR(255) NOT NULL,
  "logs"                TEXT,
  "rolled_back_at"      TIMESTAMPTZ,
  "started_at"          TIMESTAMPTZ NOT NULL DEFAULT now(),
  "applied_steps_count" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "_prisma_migrations_pkey" PRIMARY KEY ("id")
);
`;

async function main() {
  // Use DIRECT_DATABASE_URL for schema operations (bypasses pgbouncer)
  const connectionString = process.env.DIRECT_DATABASE_URL || process.env.DATABASE_URL;
  console.log('Connecting to database...');

  const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });

  try {
    await client.connect();
    console.log('Connected. Running schema creation...');
    await client.query(sql);
    console.log('✅  All tables created successfully.');
  } catch (err) {
    console.error('❌  Error:', err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
