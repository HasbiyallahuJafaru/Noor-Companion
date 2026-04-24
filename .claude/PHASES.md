# PHASES.md — Noor Companion
# Build order, current phase, and verification checklists.
# Read at the start of every session to confirm where we are.
# Update Status column as phases complete.

## The Rule

Each phase must be fully verified before the next begins.
Backend built → backend tested → Flutter built → end-to-end tested on device → confirmed → next phase.

---

## Phase Overview

| # | Phase                | Deliverable                                       | Status     |
|---|----------------------|---------------------------------------------------|------------|
| 0 | Website              | Landing page + iOS payment page on Netlify        | TODO       |
| 1 | Auth                 | Register, login, session — Flutter + backend      | TODO       |
| 2 | Content              | Dhikr, duas, recitations, Islamic APIs            | TODO       |
| 3 | Streaks              | Daily tracking, streak logic, risk notification   | TODO       |
| 4 | Therapist Directory  | List, profile, approval flow                      | TODO       |
| 5 | Calling              | Agora token, call screen, missed call             | TODO       |
| 6 | Subscriptions        | iOS + Android Paystack flows, webhook             | TODO       |
| 7 | Notifications        | FCM push, in-app feed, scheduled BullMQ job       | TODO       |
| 8 | Admin Screens        | User mgmt, therapist approval, content, broadcast | TODO       |
| 9 | Therapist Screens    | Dashboard, profile setup, incoming call           | TODO       |

---

## Phase 0 — Website (Netlify)

Two HTML pages. Static. No framework. Deployed on Netlify.

### Pages
1. index.html — Landing page (marketing)
2. subscribe.html — iOS/Android payment redirect handler

### index.html Sections
- Hero: logo, tagline "Light your way back", App Store + Play Store links
- Features: Daily Dhikr & Duas · Streak Tracking · Therapist Calls
- How It Works: 3 numbered steps
- Therapist preview section with upgrade CTA
- Footer: privacy policy link, terms link, copyright

### subscribe.html Behaviour
- Loads → extracts ?token and ?plan from URL
- Missing token → show error: "Invalid payment link. Return to the app."
- POST /api/v1/payments/subscribe-init with token
- Invalid/expired token → show error: "Link has expired. Return to the app."
- Valid → Paystack inline checkout opens automatically
- Payment success → show: "Payment complete. Return to the app."
- Checkout closed/cancelled → show: "Payment not completed." + retry button

### Verification Checklist
- [ ] Landing page renders correctly on mobile (375px) and desktop (1280px)
- [ ] All buttons and links are correct — no dead links
- [ ] App Store and Play Store links point to correct destinations (or placeholder)
- [ ] subscribe.html with no token → error message shown
- [ ] subscribe.html with expired/invalid token → error message shown
- [ ] subscribe.html with valid token → Paystack iframe opens
- [ ] Payment success screen displayed after payment
- [ ] Deployed to Netlify and live at custom URL
- [ ] HTTPS active on Netlify
- [ ] Site URL set in Supabase Auth settings

---

## Phase 1 — Auth

Build the auth infrastructure first. Everything else depends on this.

### Backend Tasks
- [ ] Create project structure (src/, prisma/, config/, etc.)
- [ ] config/env.js — Zod-validated env, server refuses to start if vars missing
- [ ] config/supabase.js — Supabase admin client (service role)
- [ ] config/prisma.js — Prisma singleton
- [ ] config/redis.js — Upstash Redis client
- [ ] config/sentry.js — Sentry initialisation
- [ ] prisma/schema.prisma — full schema from SCHEMA.md
- [ ] npx prisma migrate dev — first migration
- [ ] middleware/auth.js — verifies Supabase token, attaches req.user
- [ ] middleware/roleGuard.js — checks req.user.role
- [ ] middleware/validate.js — Zod middleware factory
- [ ] middleware/rateLimiter.js — rate limit configs
- [ ] middleware/errorHandler.js — global error handler + 404
- [ ] routes/users.routes.js — GET /me, PATCH /me, POST /me/fcm-token
- [ ] services/users.service.js — getMe, updateProfile
- [ ] controllers/users.controller.js
- [ ] app.js — full middleware chain
- [ ] server.js — HTTP server entry point
- [ ] GET /health endpoint

### Backend Test Checklist (curl or REST client)
- [ ] GET /health → 200 { status: "ok" }
- [ ] GET /api/v1/users/me without token → 401
- [ ] GET /api/v1/users/me with invalid token → 401
- [ ] GET /api/v1/users/me with valid Supabase token → 200 with user data
- [ ] PATCH /api/v1/users/me → updates firstName in database
- [ ] POST /api/v1/users/me/fcm-token → stores token in database

Note: Login and register are handled by Supabase Auth directly.
Test Supabase Auth separately via the Supabase dashboard or their API.

### Flutter Tasks
- [ ] main.dart — Sentry + Supabase + Hive + Firebase init
- [ ] core/config/app_config.dart
- [ ] core/router/app_router.dart — full GoRouter with role guards
- [ ] core/network/api_client.dart — Dio + AuthInterceptor
- [ ] core/storage/local_storage.dart — Hive wrapper
- [ ] features/auth/data/auth_repository.dart
- [ ] features/auth/domain/models/user_model.dart
- [ ] features/auth/presentation/providers/auth_provider.dart
- [ ] features/auth/presentation/screens/splash_screen.dart
- [ ] features/auth/presentation/screens/login_screen.dart
- [ ] features/auth/presentation/screens/register_screen.dart
- [ ] features/home/presentation/screens/home_screen.dart (stub)

### Flutter End-to-End Checklist
- [ ] Register as user → onboarding → stub home screen
- [ ] Register as therapist → "pending" state shown
- [ ] Login with correct credentials → home screen
- [ ] Login with wrong password → error message shown inline
- [ ] App restart with active session → home screen (no login prompt)
- [ ] App restart with expired session → login screen
- [ ] Logout → login screen, session cleared
- [ ] Navigation to /admin as non-admin → redirected to /home
- [ ] Navigation to /therapist-dashboard as user → redirected to /home

---

## Phase 2 — Content

### Backend Tasks
- [ ] services/content.service.js — CRUD + Redis cache layer
- [ ] services/islamic.service.js — Aladhan + Al-Quran Cloud proxy + cache
- [ ] controllers/content.controller.js
- [ ] controllers/islamic.controller.js
- [ ] routes/content.routes.js
- [ ] routes/islamic.routes.js
- [ ] validators/content.validator.js

### Backend Test Checklist
- [ ] GET /api/v1/content/dhikr → 200 list
- [ ] GET /api/v1/content/dhikr?tag=morning → filtered list
- [ ] GET /api/v1/content/duas → 200 list
- [ ] GET /api/v1/content/recitations → 200 list
- [ ] POST /api/v1/content/:id/progress → 200 with streak data
- [ ] GET /api/v1/islamic/prayer-times?lat=10.5&lng=7.4 → 200 with times
- [ ] GET /api/v1/islamic/quran/1 → 200 with Al-Fatiha
- [ ] GET /api/v1/islamic/hadith → 200 list
- [ ] Second call to prayer-times → served from Redis cache (check logs)
- [ ] All above without auth token → 401

### Flutter Tasks
- [ ] Full home screen (greeting, prayer strip, content cards)
- [ ] features/dhikr — library + detail + counter + audio
- [ ] features/duas — library + detail + bookmarks
- [ ] features/quran — browser + surah view + audio player
- [ ] features/prayer_times — widget on home + graceful location denial

### Flutter End-to-End Checklist
- [ ] Dhikr loads from API on first open
- [ ] Dhikr loads from Hive cache on second open (no network request visible)
- [ ] Audio plays for a dhikr item
- [ ] Dhikr counter increments, haptic fires, completion animation on target
- [ ] Engaging with dhikr updates streak count on home screen
- [ ] Prayer times display correctly for current location
- [ ] Location permission denied → city search shown

---

## Phase 3 — Streaks

### Backend Tasks
- [ ] services/streak.service.js — streak calculation logic
- [ ] routes/streaks.routes.js — GET /me
- [ ] Streak updated correctly in content.service progress handler
- [ ] BullMQ streak risk job — daily at 8 PM

### Verification Checklist
- [ ] Engaging same content twice today → streak counted once
- [ ] Engaging content on consecutive days → streak increments
- [ ] Skipping a day → streak resets to 1
- [ ] longestStreak updates when currentStreak exceeds it
- [ ] Streak risk push received at 8 PM when streak > 0 and no engagement today
- [ ] Streak badge updates correctly on home screen

---

## Phase 4 — Therapist Directory

### Backend Tasks
- [ ] services/therapists.service.js
- [ ] routes/therapists.routes.js
- [ ] Admin approval endpoints in admin.routes.js
- [ ] Approval sends FCM + Resend email to therapist

### Verification Checklist
- [ ] GET /therapists returns only active therapists
- [ ] Pending therapist does not appear in list
- [ ] Admin approves therapist → appears in list → push received by therapist
- [ ] Admin rejects therapist → push received with reason
- [ ] Therapist profile page shows correct average rating

### Flutter End-to-End Checklist
- [ ] Therapist list loads and filters work
- [ ] Therapist profile screen correct
- [ ] Free user sees locked call button with upgrade CTA
- [ ] Paid user sees active call button

---

## Phase 5 — Calling

### Backend Tasks
- [ ] utils/agora.js — token generation
- [ ] services/calling.service.js — initiate, end, missed-call worker
- [ ] routes/calls.routes.js
- [ ] BullMQ callTimeoutQueue + worker

### Verification Checklist
- [ ] POST /calls/token as free user → 403 SUBSCRIPTION_REQUIRED
- [ ] POST /calls/token as paid user → 200 with token, channelName, sessionId
- [ ] Therapist receives FCM push when call initiated
- [ ] POST /calls/:id/end → records duration in database
- [ ] After 60s with no join → session status = missed, user notified

### Flutter End-to-End Checklist
- [ ] Paid user initiates call → call screen loads
- [ ] Therapist accepts → both parties in call
- [ ] End call button → call ends, duration shown, rating prompt appears
- [ ] Therapist declines → missed call message to user
- [ ] Therapist app shows incoming call screen on push

---

## Phase 6 — Subscriptions

### Backend Tasks
- [ ] controllers/payments.controller.js
- [ ] routes/payments.routes.js (webhook + subscribe-init + subscribe-token)
- [ ] Webhook HMAC verification
- [ ] Idempotency check on payment events
- [ ] Redis cache bust after successful payment

### Verification Checklist
- [ ] POST /payments/subscribe-token → returns signed redirect URL
- [ ] POST /payments/subscribe-init with valid token → returns Paystack init data
- [ ] POST /payments/subscribe-init with expired token → 400
- [ ] Paystack webhook with valid signature → updates subscriptionTier + push sent
- [ ] Paystack webhook with invalid signature → ignored
- [ ] Duplicate webhook event → processed only once (idempotency)

### Flutter End-to-End Checklist
- [ ] iOS: tapping upgrade opens Safari to Netlify subscribe page
- [ ] iOS: after payment, app polls and reflects paid tier within 10 seconds
- [ ] Android: tapping upgrade opens WebView to Netlify subscribe page
- [ ] Android: after payment, WebView closes and tier updates
- [ ] Paid badge visible on home and profile screens

---

## Phase 7 — Notifications

### Backend Tasks
- [ ] services/notification.service.js — sendToUser, broadcastToRole
- [ ] routes/notifications.routes.js — GET /, POST /read-all
- [ ] FCM push sent on: therapist approval/rejection, call events, subscription, streak

### Flutter End-to-End Checklist
- [ ] Notifications screen shows all notifications newest-first
- [ ] Unread count badge on notifications icon
- [ ] Tapping notification navigates to correct screen
- [ ] In-app banner shows when notification arrives while app is open
- [ ] read-all marks all as read

---

## Phase 8 — Admin Screens

### Flutter Tasks
- [ ] Admin tab visible only to admin role
- [ ] Admin dashboard screen with summary cards
- [ ] User list + user detail + suspend action
- [ ] Pending therapists list + approve/reject
- [ ] Content list + add + toggle active
- [ ] Broadcast notification screen

### Verification Checklist
- [ ] Non-admin cannot access admin screens (router guard + API guard)
- [ ] Approve therapist → appears in directory immediately
- [ ] Broadcast notification → FCM push received on test device
- [ ] New content item added → visible in app after cache cleared

---

## Phase 9 — Therapist Screens

### Flutter Tasks
- [ ] Therapist dashboard tab (visible to therapists only)
- [ ] Pending state screen
- [ ] Profile setup screen — bio, specialisations, availability
- [ ] Session history screen
- [ ] Incoming call screen (FCM-triggered)

### Verification Checklist
- [ ] Pending therapist sees pending state, not dashboard
- [ ] Approved therapist can update their profile
- [ ] Session history shows correct sessions
- [ ] Incoming call push triggers call screen
- [ ] Decline incoming call → session marked cancelled
