# ARCHITECTURE.md — Noor Companion
# System design, infrastructure layout, request lifecycle, and data flow.
# Read this before making any structural or infrastructure decisions.

## System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        CLIENTS                               │
│                                                              │
│  ┌─────────────────────┐     ┌──────────────────────────┐   │
│  │   Flutter App       │     │  Website (HTML/CSS)       │   │
│  │   iOS + Android     │     │  Netlify static hosting   │   │
│  │                     │     │  Landing + iOS pay page   │   │
│  └──────────┬──────────┘     └────────────┬─────────────┘   │
└─────────────┼───────────────────────────── ┼────────────────┘
              │                              │
       ┌──────▼──────────────────────────────▼──────┐
       │              SUPABASE                       │
       │  Auth · PostgreSQL · Storage                │
       │  Flutter talks to Supabase directly for:   │
       │  - Login / register / session refresh       │
       │  - Real-time subscriptions (if needed)      │
       │  - File uploads (avatars, audio)            │
       └──────────────────┬──────────────────────────┘
                          │
       ┌──────────────────▼──────────────────────────┐
       │           BACKEND API                        │
       │    Node.js + Express on Render               │
       │                                              │
       │  Auth middleware: verifies Supabase tokens   │
       │  Business logic: streaks, calls, payments    │
       │  Proxy: Islamic API content with caching     │
       │  Webhooks: Paystack payment confirmation     │
       └──────────────────┬──────────────────────────┘
                          │
       ┌──────────────────▼──────────────────────────┐
       │            DATA & SERVICES                   │
       │                                              │
       │  Supabase PostgreSQL  — primary data store   │
       │  Upstash Redis        — cache + job queues   │
       │  Agora.io             — WebRTC call tokens   │
       │  Paystack             — payment processing   │
       │  Firebase FCM         — push notifications   │
       │  Resend               — transactional email  │
       │  Sentry               — error monitoring     │
       └──────────────────────────────────────────────┘
```

## Backend Folder Structure

```
backend/
├── src/
│   ├── app.js                   # Express setup: middleware, routes, error handler
│   ├── server.js                # HTTP server entry: binds port, connects services
│   ├── config/
│   │   ├── env.js               # Zod-validated env config — server refuses to start if invalid
│   │   ├── supabase.js          # Supabase admin client (service role key)
│   │   ├── prisma.js            # Prisma client singleton
│   │   ├── redis.js             # Upstash Redis client singleton
│   │   ├── firebase.js          # Firebase Admin SDK setup
│   │   ├── sentry.js            # Sentry init — imported first in server.js
│   │   └── resend.js            # Resend email client
│   ├── middleware/
│   │   ├── auth.js              # Verifies Supabase token → sets req.user
│   │   ├── roleGuard.js         # Checks req.user.role against allowed roles
│   │   ├── subscriptionGuard.js # Checks req.user.subscriptionTier === 'paid'
│   │   ├── rateLimiter.js       # express-rate-limit configs
│   │   ├── validate.js          # Zod validation middleware factory
│   │   └── errorHandler.js      # Global error handler + 404 handler
│   ├── routes/
│   │   ├── users.routes.js
│   │   ├── content.routes.js
│   │   ├── islamic.routes.js
│   │   ├── therapists.routes.js
│   │   ├── calls.routes.js
│   │   ├── payments.routes.js
│   │   ├── notifications.routes.js
│   │   ├── streaks.routes.js
│   │   └── admin.routes.js
│   ├── controllers/             # Thin — receive validated request, call service, respond
│   ├── services/                # All business logic lives here
│   ├── validators/              # Zod schemas — one file per domain
│   ├── utils/
│   │   ├── agora.js             # Agora RTC token generation
│   │   ├── paystack.js          # Paystack webhook HMAC verification
│   │   └── logger.js            # pino structured logger
│   └── jobs/
│       ├── queues.js            # BullMQ queue definitions
│       └── workers/             # BullMQ worker processors
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── .env.example
├── package.json
└── README.md
```

## Flutter Folder Structure

```
mobile/
├── lib/
│   ├── main.dart                      # Entry: init Sentry, Supabase, Riverpod, run app
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Brand palette
│   │   │   ├── app_text_styles.dart   # Typography scale
│   │   │   └── app_strings.dart       # All user-facing strings
│   │   ├── config/
│   │   │   └── app_config.dart        # dart-define constants (API URL, Agora App ID)
│   │   ├── router/
│   │   │   └── app_router.dart        # GoRouter with role-based redirect guards
│   │   ├── network/
│   │   │   ├── api_client.dart        # Dio instance + interceptors for backend calls
│   │   │   └── auth_interceptor.dart  # Attaches Supabase token to every backend request
│   │   └── storage/
│   │       └── local_storage.dart     # Hive wrapper for offline content cache
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── dhikr/
│   │   ├── duas/
│   │   ├── quran/
│   │   ├── prayer_times/
│   │   ├── therapists/
│   │   ├── calling/
│   │   ├── subscription/
│   │   ├── streak/
│   │   ├── notifications/
│   │   ├── profile/
│   │   ├── admin/
│   │   └── therapist_dashboard/
│   └── shared/
│       ├── widgets/
│       ├── models/
│       └── providers/
├── assets/
│   ├── images/logo.png
│   └── fonts/
└── pubspec.yaml
```

## Website Structure (Netlify)

```
website/
├── index.html           # Landing page
├── subscribe.html       # iOS payment redirect handler
├── css/
│   ├── main.css         # Shared styles + CSS variables
│   └── subscribe.css
├── js/
│   ├── main.js          # Landing page interactions
│   └── subscribe.js     # Token verify + Paystack init
├── assets/
│   ├── logo.png
│   └── og-image.png     # Social sharing image
└── _redirects           # Netlify redirect rules (SPA fallback if needed)
```

## Request Lifecycle — Backend

Every request passes through this chain:

```
Incoming request
  → Sentry request handler (must be first)
  → Helmet (security headers)
  → CORS
  → Body parser (express.json)
  → pino-http (request logging)
  → Rate limiter (on specific routes)
  → Auth middleware (verifies Supabase token, sets req.user)
  → Role guard (on role-restricted routes)
  → Subscription guard (on paid-only routes)
  → Zod validator (validates req.body / params / query)
  → Route handler
  → Service layer (business logic)
  → Prisma (database via Supabase PostgreSQL)
  → Response
  → Sentry error handler
  → Custom error handler (formats error response)
```

## Auth Middleware — How It Works

The backend does not manage JWTs. It delegates verification to Supabase.

```javascript
// Every protected request:
// 1. Extract Bearer token from Authorization header
// 2. Call supabase.auth.getUser(token) — Supabase verifies the token
// 3. If valid → attach user to req.user and continue
// 4. If invalid or expired → return 401

// req.user shape after middleware:
// {
//   id: 'supabase-user-uuid',
//   email: 'user@example.com',
//   role: 'user' | 'therapist' | 'admin',   // from user_metadata
//   subscriptionTier: 'free' | 'paid'        // from users table
// }
```

## Supabase Storage Buckets

| Bucket          | Contents                    | Access         |
|-----------------|-----------------------------|----------------|
| avatars         | User and therapist photos   | Public read    |
| content-audio   | Dhikr, dua, recitation MP3s | Public read    |

Files are uploaded directly from Flutter using supabase_flutter's storage API.
The backend does not handle file uploads — it only stores the resulting URLs.

## Caching Strategy (Upstash Redis)

| Data                        | Cache Key                  | TTL      |
|-----------------------------|----------------------------|----------|
| Dhikr list                  | content:dhikr              | 24 hours |
| Duas list                   | content:duas               | 24 hours |
| Recitations list            | content:recitations        | 24 hours |
| Prayer times (by location)  | prayer:{lat}:{lng}:{date}  | 1 hour   |
| Quran surah                 | quran:surah:{number}       | 24 hours |
| Hadith collection           | hadith:{collection}        | 24 hours |
| User profile                | user:{supabaseUserId}      | 5 min    |

Cache is invalidated explicitly when the underlying data changes.
Never serve stale subscription tier data — always invalidate user cache
immediately after a successful Paystack webhook.

## Data Flow: iOS Payment

```
1. Flutter (iOS)
   → POST /api/v1/payments/subscribe-token
   → Backend generates short-lived JWT (10 min) with { userId, plan }
   → Returns: { redirectUrl: "https://noorcompanion.netlify.app/subscribe?token=...&plan=paid" }

2. Flutter opens Safari via url_launcher

3. Netlify subscribe.html
   → Extracts token from URL
   → POST /api/v1/payments/subscribe-init { token }
   → Backend verifies token, returns { email, amountInKobo, reference, userId }
   → Paystack inline initialised with metadata: { userId }

4. User pays on Paystack

5. Paystack webhook → POST /api/v1/payments/webhook
   → Backend verifies HMAC signature
   → Updates user.subscriptionTier = 'paid' in Supabase
   → Sends FCM push: "Your subscription is active"
   → Invalidates user cache in Redis

6. Flutter (on app resume)
   → Polls GET /api/v1/users/me up to 5 times
   → Reflects new subscription tier
```

## Infrastructure Cost Estimate

| Service            | Free Tier Limit                      | Paid from          |
|--------------------|--------------------------------------|--------------------|
| Supabase           | 500MB DB, 1GB storage, 50k MAU auth  | $25/month          |
| Render (backend)   | 750h/month (spins down after 15 min) | $7/month (Starter) |
| Upstash Redis      | 10k commands/day                     | ~$0.2/100k cmds    |
| Netlify (website)  | 100GB bandwidth, 300 build min       | $19/month          |
| Firebase FCM       | Unlimited push notifications         | Free               |
| Agora              | 10,000 min/month                     | $0.0099/min        |
| Sentry             | 5k errors/month                      | $26/month          |
| Resend             | 3,000 emails/month                   | $20/month          |

**Launch cost: $0/month on free tiers across all services.**
Upgrade Render to $7/month Starter immediately to prevent spin-down in production.
