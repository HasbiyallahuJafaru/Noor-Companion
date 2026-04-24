# SCHEMA.md — Noor Companion
# Full PostgreSQL schema defined in Prisma syntax.
# This is the single source of truth for the data layer.
# Read before writing any Prisma query or migration.

## Notes on Supabase + Prisma

- DATABASE_URL points at the Supabase PostgreSQL connection string
- Use the connection pooling URL (port 6543) for the app, direct URL (port 5432) for migrations
- Supabase creates an auth.users table — our public.users table mirrors the Supabase user ID
- Never duplicate email or password in our users table — Supabase Auth owns those
- Run migrations with: npx prisma migrate deploy (not migrate dev in production)

## Full Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")       // Pooled connection — use for app
  directUrl = env("DIRECT_DATABASE_URL") // Direct connection — use for migrations
}

// ─────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────

enum Role {
  user       // Daily user — free or paid
  therapist  // Wellness professional — must be admin-approved
  admin      // Platform operator — full access
}

enum SubscriptionTier {
  free  // Content only
  paid  // Content + therapist calling
}

enum TherapistStatus {
  pending    // Registered, awaiting admin review
  active     // Approved — visible in directory, can receive calls
  rejected   // Declined by admin
  suspended  // Temporarily disabled by admin
}

enum SessionStatus {
  initiated  // Token generated, waiting for both parties to join
  active     // Both parties in the Agora channel
  completed  // Call ended normally
  missed     // Therapist did not join within 60 seconds
  cancelled  // Cancelled before starting
}

enum NotificationType {
  streak_reminder     // Daily streak nudge
  session_incoming    // Therapist receives when user starts a call
  session_completed   // Sent to both parties after call ends
  subscription_active // Payment succeeded
  therapist_approved  // Admin approved the therapist
  therapist_rejected  // Admin rejected the therapist
  general             // Admin broadcast
}

enum ContentCategory {
  dhikr      // Remembrance phrases with counters
  dua        // Supplications
  recitation // Quran recitation segments
}

// ─────────────────────────────────────────────────────────
// USER
// Mirrors Supabase auth.users via the supabase_id field.
// Supabase owns email and password — never duplicate them here.
// ─────────────────────────────────────────────────────────

model User {
  id               String           @id @default(cuid())
  supabaseId       String           @unique  // auth.users.id from Supabase
  firstName        String
  lastName         String
  role             Role             @default(user)
  subscriptionTier SubscriptionTier @default(free)
  avatarUrl        String?          // Supabase Storage public URL
  fcmToken         String?          // Firebase Cloud Messaging token — updated on login
  isActive         Boolean          @default(true)  // false = suspended / soft deleted
  lastSeenAt       DateTime?
  createdAt        DateTime         @default(now())
  updatedAt        DateTime         @updatedAt

  therapistProfile TherapistProfile?
  streak           Streak?
  sessionsAsUser   CallSession[]    @relation("UserSessions")
  notifications    Notification[]
  contentProgress  ContentProgress[]
  ratings          SessionRating[]  @relation("UserRatings")
  paymentEvents    PaymentEvent[]

  @@index([supabaseId])
}

// ─────────────────────────────────────────────────────────
// THERAPIST PROFILE
// One-to-one with User (role = therapist).
// Created on registration. Admin approval required before going live.
// ─────────────────────────────────────────────────────────

model TherapistProfile {
  id                String          @id @default(cuid())
  userId            String          @unique
  user              User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  status            TherapistStatus @default(pending)
  bio               String
  specialisations   String[]        // e.g. ["anxiety", "grief", "spiritual wellness"]
  qualifications    String[]        // e.g. ["MSc Psychology", "BACP Accredited"]
  yearsExperience   Int
  languagesSpoken   String[]        // e.g. ["English", "Arabic", "Hausa"]
  sessionRateNgn    Int             // Display rate in Naira — for UI only, not payment processing
  availabilityJson  Json?           // Weekly schedule — { monday: [{start: "09:00", end: "17:00"}] }
  approvedAt        DateTime?
  approvedByAdminId String?         // User.id of the admin who approved
  rejectionReason   String?
  createdAt         DateTime        @default(now())
  updatedAt         DateTime        @updatedAt

  sessions CallSession[]   @relation("TherapistSessions")
  ratings  SessionRating[] @relation("TherapistRatings")

  @@index([status])
}

// ─────────────────────────────────────────────────────────
// CALL SESSION
// Created when a user initiates a call. Full lifecycle tracked here.
// ─────────────────────────────────────────────────────────

model CallSession {
  id                 String           @id @default(cuid())
  userId             String
  user               User             @relation("UserSessions", fields: [userId], references: [id])
  therapistProfileId String
  therapistProfile   TherapistProfile @relation("TherapistSessions", fields: [therapistProfileId], references: [id])
  agoraChannelName   String           @unique  // noor_<cuid> — one channel per session, never reused
  status             SessionStatus    @default(initiated)
  startedAt          DateTime?        // When both parties joined the channel
  endedAt            DateTime?
  durationSeconds    Int?             // Calculated on session end
  createdAt          DateTime         @default(now())

  rating SessionRating?

  @@index([userId])
  @@index([therapistProfileId])
}

// ─────────────────────────────────────────────────────────
// SESSION RATING
// User rates a therapist after a completed call. One per session.
// ─────────────────────────────────────────────────────────

model SessionRating {
  id                 String           @id @default(cuid())
  sessionId          String           @unique
  session            CallSession      @relation(fields: [sessionId], references: [id])
  userId             String
  user               User             @relation("UserRatings", fields: [userId], references: [id])
  therapistProfileId String
  therapistProfile   TherapistProfile @relation("TherapistRatings", fields: [therapistProfileId], references: [id])
  rating             Int              // 1 to 5
  comment            String?
  createdAt          DateTime         @default(now())
}

// ─────────────────────────────────────────────────────────
// STREAK
// One record per user. Updated each day the user engages with content.
// ─────────────────────────────────────────────────────────

model Streak {
  id            String    @id @default(cuid())
  userId        String    @unique
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  currentStreak Int       @default(0)  // Consecutive days of engagement
  longestStreak Int       @default(0)  // All-time record
  lastEngagedAt DateTime?              // Used to determine if streak is still alive
  totalDays     Int       @default(0)  // Total unique days engaged (not necessarily consecutive)
  updatedAt     DateTime  @updatedAt
}

// ─────────────────────────────────────────────────────────
// CONTENT
// Platform-managed content: dhikr, duas, recitations.
// External API content (Quran, hadith, prayer times) is NOT stored here —
// it is fetched from public APIs and cached in Upstash Redis.
// ─────────────────────────────────────────────────────────

model Content {
  id              String          @id @default(cuid())
  title           String
  arabicText      String?
  transliteration String?
  translation     String?
  audioUrl        String?         // Supabase Storage public URL
  category        ContentCategory
  tags            String[]        // e.g. ["morning", "evening", "forgiveness"]
  isActive        Boolean         @default(true)
  sortOrder       Int             @default(0)  // Manual ordering within category
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt

  progress ContentProgress[]
}

// ─────────────────────────────────────────────────────────
// CONTENT PROGRESS
// Records when a user engages with a content item.
// Used to calculate streaks. Idempotent per user per item.
// ─────────────────────────────────────────────────────────

model ContentProgress {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  contentId String
  content   Content  @relation(fields: [contentId], references: [id])
  engagedAt DateTime @default(now())

  @@unique([userId, contentId])
  @@index([userId])
}

// ─────────────────────────────────────────────────────────
// NOTIFICATION
// Persistent notification records. Push sent via FCM, stored here.
// The app reads from this table to show the in-app notification feed.
// ─────────────────────────────────────────────────────────

model Notification {
  id        String           @id @default(cuid())
  userId    String
  user      User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  type      NotificationType
  title     String
  body      String
  isRead    Boolean          @default(false)
  data      Json?            // Extra context — e.g. { sessionId, therapistId }
  createdAt DateTime         @default(now())

  @@index([userId, isRead])
}

// ─────────────────────────────────────────────────────────
// PAYMENT EVENT
// Audit log of every Paystack webhook event.
// This is NOT the subscription source of truth — use User.subscriptionTier.
// Exists for debugging, refund handling, and compliance.
// ─────────────────────────────────────────────────────────

model PaymentEvent {
  id              String   @id @default(cuid())
  paystackEventId String   @unique  // Paystack event.id — prevents duplicate processing
  userId          String?
  user            User?    @relation(fields: [userId], references: [id])
  event           String   // e.g. "charge.success"
  amount          Int      // In kobo (NGN x 100)
  currency        String   @default("NGN")
  status          String   // "success" | "failed"
  rawPayload      Json     // Full webhook payload — stored for debugging
  createdAt       DateTime @default(now())
}
```

## Design Decisions

### Supabase ID as Foreign Key
Our User.supabaseId links to Supabase's auth.users.id. All auth is
handled by Supabase. Our users table only stores app-specific data.
When a new user registers, a trigger (or backend webhook on auth event)
creates the corresponding User record in our public schema.

### CUIDs as Primary Keys
Shorter than UUIDs, URL-safe, time-sortable, and collision-resistant.
Used for all our own tables. Supabase auth UUIDs are used only in supabaseId.

### No Password Storage
Supabase Auth owns passwords entirely. Our users table has no passwordHash field.

### Soft Deletes
isActive = false prevents login and hides the account without destroying
historical session and payment data.

### External Content Not Stored
Prayer times, Quran verses, and hadith are fetched from free public APIs
and cached in Redis. Storing them in PostgreSQL creates unnecessary
maintenance overhead and potential copyright exposure.
