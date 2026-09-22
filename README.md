# Noor Companion

> **Light your way back**

An Islamic spiritual wellness mobile application for daily users, verified therapists, and platform administrators. Built with Flutter and Node.js, hosted on Railway.

---

## Current State

- **Infrastructure consolidated on Railway**: API, PostgreSQL, Redis, and the static website all run as Railway services. Supabase remains **auth only** (Railway has no auth service). Third-party services without Railway equivalents stay: Firebase (FCM), Agora (calling), Resend (email), Paystack (payments), Sentry (error tracking).
- **Deployment is config-as-code**: `railway.json` (repo root) drives the API build/deploy; `website/railway.json` drives the website service. The Prisma schema is pushed at container start against Railway's private internal database URL — the database is never exposed publicly.
- **UI redesigned to the "Soft Luxury" visual world** across website and mobile: lavender-grey canvas, white cards, ink-navy pills, single teal accent, Plus Jakarta Sans, and a custom inline-SVG icon set (`flutter_svg`).
- **Hardened payment and call flows**: the Paystack webhook verifies amount and idempotency, call sessions flip to active with real durations on join, and the subscribe page's API/paystack config is injected at serve time.

---

## What It Is

Noor Companion brings together daily Islamic practice and professional mental wellness support in a single app. Users build consistent habits through dhikr, duas, and Quran recitations, track their streaks, and connect with verified Muslim therapists via in-app voice calls.

**Three roles, one app:**

| Role | What they do |
|---|---|
| User | Daily Islamic content, streak tracking, therapist directory, paid calling |
| Therapist | Profile management, session history, incoming call handling |
| Admin | User management, therapist approval, content moderation, broadcast notifications |

---

## Features

- **Daily Dhikr & Duas** — curated content library with audio playback and tasbih counter
- **Quran Browser** — surah listing with verse-by-verse audio via Al-Quran Cloud
- **Prayer Times** — location-aware prayer schedule via Aladhan API with live countdown
- **Streak System** — daily engagement tracking with milestone celebrations and at-risk push notifications (targeted at users whose streak is still salvageable, not lapsed ones)
- **Therapist Directory** — searchable, filterable directory with aggregated ratings
- **Voice Calling** — Agora RTC-powered calls between paid users and therapists, with live token renewal and missed-call detection
- **Subscriptions** — Paystack checkout in an external browser (iOS) or in-app WebView (Android), activated by a signature-verified webhook
- **Push Notifications** — FCM-powered feed with in-app unread badge and dead-token pruning
- **Admin Panel** — analytics dashboard, user/therapist/content management, broadcast notifications
- **Therapist Dashboard** — profile setup, session history, incoming call screen

---

## Tech Stack

### Backend

| Concern | Technology |
|---|---|
| Runtime | Node.js 20+ |
| Framework | Express.js |
| ORM | Prisma |
| Database | Railway PostgreSQL |
| Auth | Supabase Auth (Railway Postgres for app data) |
| Cache / Queues | Railway Redis + BullMQ |
| Validation | Zod |
| Push Notifications | Firebase Admin SDK (FCM) |
| Error Tracking | Sentry |
| Email | Resend |
| Hosting | Railway |

### Mobile (Flutter)

| Concern | Technology |
|---|---|
| Language | Dart |
| Auth | supabase_flutter |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Offline Cache | Hive |
| Fonts | google_fonts (Plus Jakarta Sans + Amiri for Arabic) |
| Icons | flutter_svg (custom NoorIcons set) |
| Audio | just_audio |
| Location | geolocator (prayer times) |
| Push Notifications | firebase_messaging |
| Voice Calling | agora_rtc_engine |
| Payments (iOS) | url_launcher → external browser |
| Payments (Android) | flutter_inappwebview |

### Infrastructure

| Service | Provider |
|---|---|
| Database | Railway PostgreSQL |
| API Hosting | Railway |
| Redis | Railway Redis |
| Website Hosting | Railway (static, `website/server.js`) |
| Auth | Supabase Auth |
| Voice Calling | Agora.io |
| Payments | Paystack |
| Push Notifications | Firebase FCM |
| Email | Resend |
| Error Tracking | Sentry (backend) |

---

## Project Structure

```
noor-companion/
+-- railway.json              Railway config: API build + deploy (schema push at start)
+-- backend/                  Node.js + Express + Prisma
|   +-- prisma/               Database schema
|   +-- scripts/              Ops scripts (create tables, grant admin)
|   +-- src/
|       +-- config/           Prisma, Redis, Supabase (auth), Firebase, Sentry, env validation
|       +-- middleware/       Auth (local JWT verify + user cache), role guard, validation, rate limiter, error handler
|       +-- routes/           Express routers (users, content, calls, payments, etc.)
|       +-- services/         Business logic layer
|       +-- controllers/      Request/response handlers
|       +-- validators/       Zod schemas
|       +-- workers/          BullMQ workers (streak risk, call timeout)
|       +-- __tests__/        Jest test suites
|       +-- utils/            Agora token generation, email helpers
+-- mobile/                   Flutter application
|   +-- lib/
|       +-- core/             Config, router, theme, NoorIcons, network client, shell
|       +-- features/         Feature modules (auth, dhikr, duas, quran, calls, etc.)
|       +-- shared/           Shared widgets and utilities
+-- website/                  Static site on Railway (landing, pricing, Paystack redirect page)
+-- .claude/                  Project documentation for AI-assisted development
```

---

## Getting Started

### Prerequisites

- Node.js 20+
- Flutter 3.x with Dart 3.x
- A PostgreSQL database and Redis instance (local, or Railway)
- A Supabase project (auth only)
- An Agora.io account and app
- A Paystack account
- Firebase project with FCM enabled

### Backend Setup

```bash
cd backend
npm install
```

Copy `.env.example` to `.env` and fill in all required values (see `.claude/ENV.md` for descriptions).

Create the schema:

```bash
npx prisma db push
npx prisma generate
```

Start the development server:

```bash
npm run dev
```

Run the test suite:

```bash
npm test
```

### Flutter Setup

```bash
cd mobile
flutter pub get
flutter analyze
```

Run with environment variables:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=AGORA_APP_ID=your_agora_app_id \
  --dart-define=WEBSITE_URL=https://your-website.up.railway.app
```

Firebase must be configured separately via:

```bash
flutterfire configure
```

---

## Deployment (Railway)

Full runbook in `.claude/ENV.md`. Summary:

1. **API service** — from the repo root; `railway.json` handles build (`npm install && prisma generate`) and start (`prisma db push && node src/server.js`).
2. **Databases** — add Railway PostgreSQL and Redis, then reference their private URLs as service variables: `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`, `REDIS_URL` = `${{Redis.REDIS_URL}}`.
3. **Website service** — same repo, root directory `/website`, config `website/railway.json`. `website/server.js` serves static files with clean URLs and the security headers (including the Paystack-scoped CSP on `/subscribe`).
4. **Data migration from Supabase** (one-time) — `pg_dump --data-only` from Supabase piped into `psql` on the Railway URL. Auth users stay in Supabase; the app's `User` table mirrors them via `supabaseId`.

---

## Architecture Notes

### Auth

Supabase Auth owns the full authentication lifecycle; the backend never stores credentials. Flutter sends the Supabase access token as a Bearer header on every API call. The backend verifies it **locally** with `SUPABASE_JWT_SECRET` when configured (no network roundtrip), falling back to `supabase.auth.getUser(token)` otherwise — and caches the resolved app user in memory for 30 seconds.

Roles (`user`, `therapist`, `admin`) are mirrored in the `users` table. Signup metadata is client-controlled, so the auth middleware only ever self-selects `user` or `therapist` — `admin` is granted out-of-band via `backend/scripts/make-admin.js`. Subscription tier (`free`, `paid`) is updated exclusively by the Paystack webhook, which verifies the HMAC signature, enforces idempotency, and checks the charged amount.

### Payments

Apple prohibits third-party in-app payment processors. The iOS flow opens an external browser to the hosted website (`/subscribe`) where the user pays via Paystack; the app picks up the result via the `noorcompanion://payment-success` deep link and polls `GET /users/me` to confirm the upgrade. Android uses an in-app WebView. The webhook responds 200 immediately (Paystack's retry contract) and processes asynchronously with idempotent event storage.

### Voice Calling

Agora RTC tokens are generated server-side with a 1-hour expiry. Connecting participants flip the session from `initiated`/`missed` to `active` via `POST /calls/:sessionId/renew-token`, which stamps `startedAt` (real durations) and prevents the 60-second timeout from marking answered calls as missed. Both parties can end the call; only the caller can rate it. Calls are rate-limited to 5 initiations per minute.

### Background Jobs

Two BullMQ workers run on server startup (Railway services don't spin down, so schedules hold):

- **Streak risk** — daily at 8 PM UTC, FCM to users who engaged *yesterday* but not today (their streak can still be saved; lapsed users are excluded, since engaging after a lapse resets the streak)
- **Call timeout** — 60 seconds after initiation, marks unanswered sessions as missed and notifies the caller

---

## Brand

Visual world: **Soft Luxury** — lavender canvas, white cards, ink pills, one teal accent.

| Token | Value |
|---|---|
| Canvas (lavender grey) | `#F2F1F8` |
| Surface | `#FFFFFF` |
| Ink (primary actions) | `#171930` |
| Accent (teal) | `#17C3B2` (fills) / `#0B8A7E` (text-safe) |
| Streak gold | `#E8A33D` — streaks and premium only |
| Type | Plus Jakarta Sans (UI) + Amiri (Arabic) |
| Shapes | cards 20-32px, all interactive controls pill |

---

## License

Private repository. All rights reserved.
