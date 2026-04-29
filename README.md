# Noor Companion

> **Light your way back**

An Islamic spiritual wellness mobile application for daily users, verified therapists, and platform administrators. Built with Flutter and Node.js.

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

- **Daily Dhikr & Duas** — curated content library with audio playback and counter
- **Quran Browser** — surah listing with verse-by-verse audio via Al-Quran Cloud
- **Prayer Times** — location-aware prayer schedule via Aladhan API
- **Streak System** — daily engagement tracking with milestone celebrations and at-risk push notifications
- **Therapist Directory** — searchable, filterable directory of verified Muslim wellness professionals
- **Voice Calling** — Agora RTC-powered calls between paid users and therapists
- **Subscriptions** — iOS (Safari redirect) and Android (WebView) Paystack payment flows
- **Push Notifications** — FCM-powered feed with in-app unread badge
- **Admin Panel** — analytics dashboard, user/therapist/content management, broadcast notifications
- **Therapist Dashboard** — profile setup, session history, incoming call screen

---

## Tech Stack

### Backend

| Concern | Technology |
|---|---|
| Runtime | Node.js |
| Framework | Express.js |
| ORM | Prisma |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Cache / Queues | Upstash Redis + BullMQ |
| Validation | Zod |
| Push Notifications | Firebase Admin SDK (FCM) |
| Error Tracking | Sentry |
| Email | Resend |
| Hosting | Render |

### Mobile (Flutter)

| Concern | Technology |
|---|---|
| Language | Dart |
| Auth + Realtime | supabase_flutter |
| State Management | Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Offline Cache | Hive |
| Push Notifications | firebase_messaging |
| Voice Calling | agora_rtc_engine |
| Permissions | permission_handler |
| Payments (iOS) | url_launcher -> Safari |
| Payments (Android) | flutter_inappwebview |
| Error Tracking | Sentry Flutter SDK |

### Infrastructure

| Service | Provider |
|---|---|
| Database | Supabase |
| Backend Hosting | Render |
| Redis | Upstash |
| Website Hosting | Netlify |
| Voice Calling | Agora.io |
| Payments | Paystack |
| Push Notifications | Firebase FCM |
| Email | Resend |
| Error Tracking | Sentry |

---

## Project Structure

```
noor-companion/
+-- backend/                  Node.js + Express + Prisma
|   +-- prisma/               Database schema and migrations
|   +-- src/
|       +-- config/           Supabase, Prisma, Redis, Sentry, env validation
|       +-- middleware/        Auth, role guard, validation, rate limiter, error handler
|       +-- routes/           Express routers (users, content, calls, payments, etc.)
|       +-- services/         Business logic layer
|       +-- controllers/      Request/response handlers
|       +-- validators/       Zod schemas
|       +-- workers/          BullMQ workers (streak risk, call timeout)
|       +-- utils/            Agora token generation, email helpers
+-- mobile/                   Flutter application
|   +-- lib/
|       +-- core/             App config, router, theme, network client, services
|       +-- features/         Feature modules (auth, dhikr, duas, quran, etc.)
|       +-- shared/           Shared widgets and utilities
+-- website/                  Static Netlify site (landing + Paystack redirect page)
+-- .claude/                  Project documentation for AI-assisted development
```

---

## Getting Started

### Prerequisites

- Node.js 20+
- Flutter 3.x with Dart 3.x
- A Supabase project
- An Agora.io account and app
- A Paystack account
- Firebase project with FCM enabled
- Upstash Redis instance

### Backend Setup

```bash
cd backend
npm install
```

Copy `.env.example` to `.env` and fill in all required values (see `.claude/ENV.md` for descriptions).

Run the database migration:

```bash
npx prisma migrate dev
npx prisma generate
```

Start the development server:

```bash
npm run dev
```

### Flutter Setup

```bash
cd mobile
flutter pub get
```

Run with environment variables:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=AGORA_APP_ID=your_agora_app_id \
  --dart-define=SENTRY_DSN=your_sentry_dsn \
  --dart-define=WEBSITE_URL=https://noorcompanion.netlify.app
```

Firebase must be configured separately via:

```bash
flutterfire configure
```

---

## Architecture Notes

### Auth

Supabase Auth owns the full authentication lifecycle. The backend never generates JWTs or stores refresh tokens. Flutter sends the Supabase access token as a Bearer header on every API call; the backend verifies it by calling `supabase.auth.getUser(token)`.

Roles (`user`, `therapist`, `admin`) are stored in Supabase `user_metadata` and mirrored in the `users` table for Prisma queries. Subscription tier (`free`, `paid`) is stored in the database and updated exclusively by the Paystack webhook handler.

### Payments

Apple prohibits third-party in-app payment processors. The iOS flow opens Safari to a hosted Netlify page where the user pays via Paystack; the app polls `GET /users/me` on return to confirm the upgrade. Android uses an in-app WebView and intercepts the `noorcompanion://payment-success` URI scheme.

### Voice Calling

Agora RTC tokens are generated server-side with a 1-hour expiry. The app handles `onTokenPrivilegeWillExpire` to request a fresh token from `POST /calls/:sessionId/renew-token` and call `engine.renewToken()` without dropping the call. Calls are rate-limited to 5 initiations per minute per user.

### Background Jobs

Two BullMQ workers run on server startup:

- **Streak risk** — fires daily at 8 PM UTC, sends FCM to users who have a streak but no engagement today
- **Call timeout** — fires 60 seconds after a call is initiated; marks the session as missed and notifies the caller if the therapist has not joined

---

## Brand

| Token | Value |
|---|---|
| Primary (Teal) | `#0D7C6E` |
| Accent (Gold) | `#C9933A` |
| Text (Dark) | `#1A1A2E` |
| Background | `#F7F8FA` |

---

## License

Private repository. All rights reserved.
