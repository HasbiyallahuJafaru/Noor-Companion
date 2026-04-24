# CLAUDE.md — Noor Companion
# Master reference for every Claude Code session.
# Read this file completely before writing any code.

## What This Project Is

Noor Companion is an Islamic spiritual wellness mobile application serving three
user types — daily users, therapists, and administrators — all within a single
Flutter app using role-based access control.

The platform combines daily Islamic content (dhikr, duas, Quran recitations),
prayer times, a therapist directory, in-app audio/video calling between users
and therapists (paid tier only), streak-based habit tracking, and push
notifications into one cohesive product.

App name: Noor Companion
Tagline: Light your way back
Brand: Teal #0D7C6E (primary) · Gold #C9933A (accent) · Dark #1A1A2E (text)

---

## Repo Structure

```
noor-companion/
├── .claude/
│   ├── CLAUDE.md          ← This file. Read first.
│   ├── ARCHITECTURE.md    ← System design, data flow, infrastructure
│   ├── SCHEMA.md          ← Prisma schema — full database definition
│   ├── API_CONTRACT.md    ← Every endpoint: method, auth, request, response
│   ├── BACKEND_GUIDE.md   ← Node.js patterns, folder structure, conventions
│   ├── FLUTTER_GUIDE.md   ← Flutter architecture, Riverpod, GoRouter, Supabase
│   ├── FEATURES.md        ← Every feature broken down in detail
│   ├── ENV.md             ← All environment variables with descriptions
│   ├── PAYMENTS.md        ← Paystack iOS redirect + Android in-app flows
│   ├── CALLING.md         ← Agora WebRTC setup, token logic, call lifecycle
│   └── PHASES.md          ← Build order — current phase and checklist
├── backend/               ← Node.js + Express + Prisma
├── mobile/                ← Flutter application
└── website/               ← Static HTML/CSS — Netlify
```

---

## Session Start Protocol

Every session, no exceptions:

1. Read CLAUDE.md (this file)
2. Read PHASES.md to confirm the current phase
3. Read the guide for today's work area:
   - Backend → BACKEND_GUIDE.md + API_CONTRACT.md + SCHEMA.md
   - Flutter → FLUTTER_GUIDE.md + FEATURES.md
   - Payments → PAYMENTS.md
   - Calling → CALLING.md
4. Run graphify
5. Check git log --oneline -10 to see what was last built
6. Never assume context — read the file

---

## Final Unified Stack

### Backend
| Concern         | Tool                                        |
|-----------------|---------------------------------------------|
| Runtime         | Node.js                                     |
| Framework       | Express.js                                  |
| ORM             | Prisma (pointed at Supabase PostgreSQL)     |
| Database        | Supabase PostgreSQL                         |
| Auth            | Supabase Auth (owns login/register/session) |
| Storage         | Supabase Storage (audio files, avatars)     |
| Cache / Queues  | Upstash Redis + BullMQ                      |
| Validation      | Zod                                         |
| Push notifs     | Firebase Admin SDK (FCM)                    |
| Error tracking  | Sentry (@sentry/node)                       |
| Email           | Resend                                      |
| Hosting         | Render Web Service                          |

### Mobile (Flutter)
| Concern         | Tool                                        |
|-----------------|---------------------------------------------|
| Language        | Dart                                        |
| Auth + DB       | supabase_flutter SDK                        |
| State mgmt      | Riverpod                                    |
| Navigation      | GoRouter                                    |
| HTTP            | Dio (backend API calls only)                |
| Offline cache   | Hive                                        |
| Push notifs     | firebase_messaging                          |
| Calling         | agora_rtc_engine                            |
| Payments iOS    | url_launcher → Safari → Netlify page        |
| Payments Android| flutter_inappwebview (Paystack WebView)     |
| Error tracking  | Sentry Flutter SDK                          |
| Design system   | hasbiy-flutter skill conventions            |

### Infrastructure
| Service         | Provider                                    |
|-----------------|---------------------------------------------|
| Database        | Supabase                                    |
| Auth            | Supabase                                    |
| Storage         | Supabase                                    |
| Backend hosting | Render Web Service                          |
| Redis           | Upstash                                     |
| Website hosting | Netlify (static)                            |
| Calling         | Agora.io                                    |
| Payments        | Paystack                                    |
| Push notifs     | Firebase FCM                                |
| Email           | Resend                                      |
| Errors          | Sentry                                      |

---

## How Supabase Auth Works in This Project

Supabase Auth owns the full login/register/session lifecycle.
The backend does NOT manage passwords, JWTs, or refresh tokens.

Flow:
1. Flutter calls supabase.auth.signUp() or supabase.auth.signInWithPassword()
2. Supabase returns a session object: { access_token, refresh_token, user }
3. supabase_flutter stores and auto-refreshes the session
4. For backend API calls, Flutter sends the Supabase access_token as Bearer token
5. Backend middleware calls supabase.auth.getUser(token) to verify identity
6. req.user is set from the verified Supabase user object
7. Role and subscriptionTier are stored in Supabase's user_metadata

The backend NEVER generates its own JWTs.
The backend NEVER stores refresh tokens.
All session management is delegated entirely to Supabase.

---

## User Roles

Roles are stored in Supabase user_metadata.role and mirrored in the
users table for Prisma queries.

| Role      | Description                                      |
|-----------|--------------------------------------------------|
| user      | Daily users — free or paid subscription          |
| therapist | Verified wellness professionals (admin-approved) |
| admin     | Platform operators — full access                 |

Role is set on registration and never changed by the client.
The backend verifies role from the Supabase token on every protected route.

---

## Subscription Tiers

| Tier | What It Unlocks                                              |
|------|--------------------------------------------------------------|
| free | Dhikr, duas, recitations, Islamic API content, streak system |
| paid | Everything free + in-app therapist calling                   |

subscriptionTier is stored in the users table (Prisma).
It is updated by the Paystack webhook handler — never by the client.

---

## Therapist Approval Flow

1. Therapist registers via supabase.auth.signUp() with role = therapist
2. Status in therapist_profiles table is set to pending
3. Admin sees pending therapists in the admin screen
4. Admin taps Approve or Reject
5. Approved → status = active, therapist appears in directory, push sent
6. Rejected → status = rejected, reason stored, push sent

---

## iOS Payment Flow (App Store Compliant)

Apple prohibits third-party in-app payment processors.
This is the compliant workaround:

1. User taps "Upgrade" on iOS
2. Backend generates a short-lived signed token (10 min)
3. App opens: https://noorcompanion.netlify.app/subscribe?token=JWT&plan=paid
4. User pays via Paystack on the Netlify page
5. Paystack webhook fires to the backend
6. Backend verifies signature, updates user.subscriptionTier = paid in Supabase
7. App polls GET /api/v1/users/me on return to confirm upgrade

---

## Android Payment Flow

1. User taps "Upgrade" on Android
2. flutter_inappwebview opens the same Netlify subscribe page
3. User pays via Paystack
4. App intercepts the success redirect, closes WebView
5. App calls GET /api/v1/users/me to refresh tier

---

## Calling Flow (Paid Users Only)

1. Paid user opens a therapist profile, taps "Start Call"
2. POST /api/v1/calls/token — backend checks paid tier, generates Agora RTC token
3. Backend creates CallSession record, sends FCM push to therapist
4. Both parties join the Agora channel with the token
5. On call end → POST /api/v1/calls/:sessionId/end, duration recorded
6. User prompted to rate the session

---

## Non-Negotiable Code Standards

### Every File
- Header comment: what this file does and why it exists
- No file longer than 300 lines — split before hitting this

### Every Function
- JSDoc (backend) or Dart doc (Flutter)
- Describe: what it receives, what it returns, any side effects
- No function longer than 50 lines — split it

### Naming
- Names describe exactly what a thing is or does
- No abbreviations except: req, res, ctx, id, err, db
- Booleans start with is, has, can, or should

### Error Handling
- Every async operation wrapped in try/catch
- Errors captured in Sentry before responding
- API errors always: { success: false, error: { code, message } }
- Never expose stack traces or Prisma errors to the client

### Security
- All non-public routes require Supabase auth middleware
- Every endpoint validates input with Zod before touching the database
- Auth routes rate-limited
- Never log tokens, passwords, or payment details

### Packages
- Always run: npm info <package> version before installing
- Never hardcode versions from memory

---

## What Claude Code Must Never Do

- Skip the session start protocol
- Write a file over 300 lines without splitting it
- Write a function over 50 lines without splitting it
- Return raw Prisma errors or Supabase errors to the API client
- Write a route handler without Zod validation
- Write auth middleware from scratch — Supabase handles auth
- Trust role or subscriptionTier from the client request body
- Hardcode any secret or credential — environment variables only
- Integrate any third-party API without reading its official docs first
- Generate its own JWTs — Supabase owns all token generation
