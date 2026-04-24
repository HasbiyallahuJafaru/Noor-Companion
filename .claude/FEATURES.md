# FEATURES.md — Noor Companion
# Detailed spec for every feature in the V1 build.
# Read the relevant section before building any feature.

## Feature Index
1. Auth & Onboarding
2. Home Feed
3. Dhikr
4. Duas
5. Quran Recitations
6. Prayer Times
7. Streak System
8. Therapist Directory & Profiles
9. In-App Calling (Paid)
10. Subscription & Upgrade
11. Push Notifications
12. Admin Panel (In-App)
13. Therapist Dashboard (In-App)
14. Profile & Settings

---

## 1. Auth & Onboarding

### Registration
- Fields: first name, last name, email, password
- Role selector: "I'm here for wellness" (user) vs "I'm a therapist" (therapist)
- Calls: supabase.auth.signUp() with metadata { firstName, lastName, role }
- On success: Supabase auth event fires → backend creates User record via a
  Supabase database webhook (trigger on auth.users insert) or via the
  first authenticated backend call
- Error states: email already exists, weak password, network error

### Onboarding (User Role Only — One Time)
Three-screen flow shown once after first registration:
1. Spiritual goal: consistency / knowledge / inner peace / healing
2. Practice level: beginner / intermediate / practising
3. Content preference: text / audio / both
Stored in Hive locally. Used to personalise home feed ordering (V1: simple).

### Login
- Email + password
- Show/hide password toggle
- Forgot password link → Supabase sends reset email
- On success: supabase_flutter persists session, GoRouter redirects to home

### Session Persistence
- supabase_flutter stores the session in secure storage automatically
- On app launch: AuthNotifier checks currentSession, calls /users/me if present
- Expired sessions: supabase_flutter auto-refreshes before making API calls

---

## 2. Home Feed

First screen after login. Content adapts to time of day.

### Layout
- Greeting: "Assalamu alaikum, [firstName]"
- Streak banner: flame icon + current count (gold when > 0, grey when 0)
- Prayer times strip: next prayer name + countdown
- Featured dhikr card: daily highlight with audio play button
- Content rows (horizontal scroll):
  - Morning Adhkar (shown before Dhuhr)
  - Evening Adhkar (shown after Asr)
  - Dua of the day
  - Quran recitation card
- "Talk to a therapist" section (below the fold):
  - Paid users: therapist cards with "Call Now"
  - Free users: locked state with upgrade CTA

### Loading Strategy
- Prayer times fetched with device location on mount (cached 1 hour)
- Content loaded from Hive cache immediately (no loading flash)
- Background refresh updates cache silently

---

## 3. Dhikr

### Dhikr Library Screen
- Grid layout, organised by tag (morning, evening, general, forgiveness)
- Each card: Arabic name, English name, subtle background

### Dhikr Detail Screen
- Arabic text (large, right-aligned, appropriate Arabic font)
- Transliteration in smaller text below
- English translation
- Audio play/pause button (Supabase Storage URL via just_audio)
- Tasbih counter: large tappable area in the centre
  - Target count displayed (e.g. 33×) — configurable per dhikr item
  - Haptic feedback on each tap (light) and on reaching target (medium)
  - Completion animation on reaching target count
- "Mark Complete" calls POST /api/v1/content/:id/progress

### Offline
- All dhikr content cached in Hive on first load
- Counter state is local — works fully offline
- Audio caches on first play

---

## 4. Duas

### Dua Library Screen
- List view, grouped by occasion: morning, evening, eating, sleeping,
  travel, anxiety, forgiveness, protection
- Search bar: filter by title or translation keyword

### Dua Detail Screen
- Same layout as dhikr but no counter
- Bookmark toggle: saved to Hive for quick access
- Bookmarked duas accessible from profile/settings as "My Duas"

---

## 5. Quran Recitations

Source: Al-Quran Cloud API proxied and cached by the backend.

### Recitation Browser Screen
- Surah list: Arabic name, English name, verse count, revelation type
- Search by name or number

### Surah View Screen
- Verse-by-verse display with Arabic + translation
- Audio player at bottom: play full surah
- Verse highlighting scrolls as audio plays (if position data available)
- Progress recorded when user reaches the last verse

---

## 6. Prayer Times

Source: Aladhan API proxied and cached by the backend (1 hour TTL).

### Home Screen Widget
- Five daily prayers with their times
- Current prayer period highlighted in teal
- Countdown timer to next prayer
- Location permission requested on first use

### Graceful Degradation
- Location denied: show city search field
- Network error: show last cached times with "times may be inaccurate" note

---

## 7. Streak System

### Logic (Backend)
On POST /api/v1/content/:id/progress:
- Load user's Streak record
- If lastEngagedAt was today → no change (already counted)
- If lastEngagedAt was yesterday → currentStreak += 1
- If lastEngagedAt was 2+ days ago → currentStreak = 1 (reset)
- If currentStreak > longestStreak → longestStreak = currentStreak
- Update lastEngagedAt to now, totalDays += 1

### UI
- Home screen: flame icon with count
- Gold (#C9933A) when currentStreak > 0
- Grey when currentStreak = 0
- Milestone celebrations at 7, 14, 30, 100 days — full-screen overlay animation

### Streak Risk Push Notification
BullMQ job runs daily at 8 PM local time (approximate — UTC-based).
Targets users whose lastEngagedAt was yesterday or earlier, streak > 0.
Message: "Your [N]-day streak is at risk. Open Noor Companion before midnight."

---

## 8. Therapist Directory & Profiles

### Therapist List Screen
- Shows only status = active therapists
- Filter chips: specialisation, language
- Each card: avatar, name, top 2 specialisations, star rating, rate in NGN
- Paid users: "Call" button active on each card
- Free users: "Upgrade" overlay on each card

### Therapist Profile Screen
- Full bio, all specialisations, qualifications, experience, languages
- Average star rating + total sessions
- Availability schedule (from availabilityJson)
- "Start Call" → paid flow
- "Upgrade to call" → free flow

### No Booking/Scheduling in V1
Calls are ad-hoc. User taps call, therapist gets push notification.
If therapist doesn't join in 60 seconds → missed call.

---

## 9. In-App Calling (Paid Users Only)

### Pre-Call
- User taps "Start Call" on therapist profile
- App calls POST /api/v1/calls/token
- Shows "Connecting..." state

### Therapist Receives Call
- Push notification: "Incoming Call from [user firstName]"
- If app open: full-screen incoming call modal
- If backgrounded: system notification with Accept action
- Accept → join Agora channel using token from notification data payload
- Decline → POST /api/v1/calls/:sessionId/end

### Call Screen
- Full-screen remote video
- Local video PiP (bottom corner, moveable)
- Controls: mute, camera toggle, end call (red)
- Timer at top showing call duration

### Post-Call
- Duration display
- Rate the session: 1–5 stars + optional comment
- Rating is optional — user can skip

### Missed Call
- After 60 seconds with no therapist join → session status = missed
- User sees: "Therapist was unavailable. Try again later."

---

## 10. Subscription & Upgrade

### Upgrade Screen
- Features list: what paid unlocks (calling)
- Single CTA: "Subscribe — ₦X,000/month" (amount TBD by client)

### iOS Flow
- Tap "Subscribe" → POST /api/v1/users/me/subscribe-token
- url_launcher opens Safari to Netlify subscribe page
- User pays on website
- On app resume: poll /users/me up to 5 times (2s intervals)
- Show "Checking subscription..." while polling
- On confirmed: navigate to home with success banner

### Android Flow
- Tap "Subscribe" → POST /api/v1/users/me/subscribe-token
- flutter_inappwebview opens the Netlify subscribe page
- Intercept Paystack success redirect
- Close WebView, call /users/me, navigate to home

### Free Tier Behaviour
- All content accessible (dhikr, duas, recitations, prayer times)
- Therapist directory browsable
- Calling gated — upgrade CTA shown instead of call button

---

## 11. Push Notifications

### FCM Setup
- FCM token registered via POST /api/v1/users/me/fcm-token on every login
- Token auto-refreshes via firebase_messaging.onTokenRefresh listener

### Notification Types

| Type               | When                         | Recipient  |
|--------------------|------------------------------|------------|
| streak_reminder    | Daily 8 PM if streak at risk | User       |
| session_incoming   | User initiates call          | Therapist  |
| session_completed  | Call ends                    | Both       |
| subscription_active| Paystack webhook success     | User       |
| therapist_approved | Admin approves therapist     | Therapist  |
| therapist_rejected | Admin rejects therapist      | Therapist  |
| general            | Admin broadcast              | Target role|

### In-App Banner
When the app is in the foreground, show a custom in-app banner at the top
of the screen instead of the system notification tray.

### Navigation on Tap
Tapping a notification navigates to the relevant screen:
- session_incoming → call screen
- session_completed → session history
- streak_reminder → home screen
- subscription_active → home screen

---

## 12. Admin Panel (In-App)

Role guard: role === admin only. Admin tab visible only to admins.

### Admin Home
- Summary cards: total users, paid subscribers, pending therapists, calls today

### User Management
- Searchable list with role and tier filters
- Tap user: profile, last seen, subscription
- Actions: suspend (isActive = false), manually set subscription tier

### Therapist Management
- Pending tab: list of pending therapists with qualifications
- Active tab: list of active therapists
- Approve → POST /api/v1/admin/therapists/:id/approve
- Reject → prompt for reason → POST /api/v1/admin/therapists/:id/reject

### Content Management
- List all content items with category badge
- Toggle active/inactive per item
- Add new item: title, Arabic, transliteration, translation, category, tags
- Audio upload via Supabase Storage SDK from Flutter

### Broadcast Notifications
- Title + body fields
- Target: All / Users / Therapists
- Send → POST /api/v1/admin/notifications/broadcast

---

## 13. Therapist Dashboard (In-App)

Role guard: role === therapist only.

### Pending State
If therapistProfile.status === pending, show:
"Your application is under review. We'll notify you once approved."

### Dashboard Home (Active Therapists)
- Total sessions, average rating
- Recent session list

### Profile Management
- Edit bio, specialisations, qualifications, session rate
- Upload profile photo (Supabase Storage)
- Set availability: weekly grid picker

### Session History
- List of past sessions: user first name (anonymised), date, duration, rating received

### Incoming Calls
- FCM push with type = session_incoming shows full-screen incoming call modal
- Accept → join Agora channel → call screen
- Decline → POST /api/v1/calls/:sessionId/end

---

## 14. Profile & Settings

### Profile Screen
- Avatar (tap to upload)
- Full name, email (read-only — managed by Supabase)
- Subscription tier badge
- Streak summary

### Settings
- Notification preferences (per type toggle)
- Biometric login toggle
- Change password (redirects to Supabase email flow)
- Delete account (isActive = false, supabase.auth.signOut())
- Logout

### About
- App version
- Privacy Policy (WebView → Netlify page)
- Terms of Service (WebView → Netlify page)
- Contact Support (email client)
