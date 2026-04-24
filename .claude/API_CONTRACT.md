# API_CONTRACT.md — Noor Companion
# Every backend API endpoint with method, auth, request, and response.
# Base URL: https://api.noorcompanion.com/api/v1
# All success responses: { success: true, data: {} }
# All error responses: { success: false, error: { code, message } }

## Authentication

All protected routes require:
  Authorization: Bearer <supabase_access_token>

The Supabase access_token is obtained from supabase.auth.signIn() in Flutter.
It is automatically refreshed by supabase_flutter. The backend validates it
by calling supabase.auth.getUser(token) — it does NOT generate its own tokens.

Public routes (no auth needed): POST /payments/webhook, GET /health

---

## Users — /api/v1/users

### GET /api/v1/users/me
Returns the authenticated user's full profile including streak.

Response 200:
```json
{
  "success": true,
  "data": {
    "id": "cuid",
    "supabaseId": "uuid",
    "firstName": "Amina",
    "lastName": "Yusuf",
    "role": "user",
    "subscriptionTier": "free",
    "avatarUrl": null,
    "isActive": true,
    "streak": {
      "currentStreak": 5,
      "longestStreak": 12,
      "totalDays": 23,
      "lastEngagedAt": "2025-04-22T08:00:00Z"
    }
  }
}
```

### PATCH /api/v1/users/me
Update profile fields. Only firstName, lastName, avatarUrl are editable.

Request:
```json
{
  "firstName": "Amina",
  "lastName": "Yusuf",
  "avatarUrl": "https://supabase.co/storage/v1/object/public/avatars/..."
}
```

Response 200:
```json
{ "success": true, "data": { "message": "Profile updated." } }
```

### POST /api/v1/users/me/fcm-token
Register or update the device FCM token for push notifications.
Call this on every login and when firebase_messaging refreshes the token.

Request:
```json
{ "fcmToken": "firebase-device-token..." }
```

Response 200:
```json
{ "success": true, "data": { "message": "FCM token registered." } }
```

### POST /api/v1/users/me/subscribe-token
iOS only. Generates the signed redirect URL for Paystack on the Netlify site.
Token expires in 10 minutes.

Response 200:
```json
{
  "success": true,
  "data": {
    "redirectUrl": "https://noorcompanion.netlify.app/subscribe?token=jwt...&plan=paid"
  }
}
```

---

## Content — /api/v1/content

### GET /api/v1/content/dhikr
Returns all active dhikr items. Cached in Redis 24 hours.

Query: ?tag=morning (optional)

Response 200:
```json
{
  "success": true,
  "data": [
    {
      "id": "cuid",
      "title": "SubhanAllah",
      "arabicText": "سُبْحَانَ اللَّهِ",
      "transliteration": "SubhanAllah",
      "translation": "Glory be to Allah",
      "audioUrl": "https://supabase.co/storage/v1/object/public/content-audio/...",
      "tags": ["morning", "general"],
      "sortOrder": 1
    }
  ]
}
```

### GET /api/v1/content/duas
Same shape as dhikr. Query: ?tag=anxiety

### GET /api/v1/content/recitations
Same shape. Returns recitation metadata with audioUrl.

### POST /api/v1/content/:contentId/progress
Mark a content item as engaged. Updates streak. Idempotent per day.

Response 200:
```json
{
  "success": true,
  "data": {
    "message": "Progress recorded.",
    "streak": { "currentStreak": 6, "longestStreak": 12 }
  }
}
```

---

## Islamic APIs (Proxied + Cached) — /api/v1/islamic

The backend proxies these from public APIs and caches in Redis.
Flutter never calls external Islamic APIs directly.

### GET /api/v1/islamic/prayer-times
Query: lat (required), lng (required), date (optional YYYY-MM-DD)

Response 200:
```json
{
  "success": true,
  "data": {
    "date": "2025-04-22",
    "fajr": "05:12",
    "sunrise": "06:28",
    "dhuhr": "12:45",
    "asr": "16:20",
    "maghrib": "18:52",
    "isha": "20:15"
  }
}
```

### GET /api/v1/islamic/quran/:surahNumber
Returns surah data with verses, translations, and audio URL.
Cached 24 hours.

Response 200:
```json
{
  "success": true,
  "data": {
    "number": 1,
    "name": "Al-Fatiha",
    "englishName": "The Opening",
    "numberOfAyahs": 7,
    "verses": [
      {
        "number": 1,
        "arabic": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
        "translation": "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
        "audioUrl": "https://cdn.alquran.cloud/media/audio/..."
      }
    ]
  }
}
```

### GET /api/v1/islamic/hadith
Query: collection (optional), limit (default 10)

Response 200:
```json
{
  "success": true,
  "data": [
    {
      "id": "bukhari:1",
      "collection": "Bukhari",
      "arabic": "...",
      "english": "Actions are judged by intentions..."
    }
  ]
}
```

---

## Therapists — /api/v1/therapists

### GET /api/v1/therapists
Returns all active (approved) therapists. Paginated.

Query: ?specialisation=anxiety&language=English&page=1&limit=20

Response 200:
```json
{
  "success": true,
  "data": {
    "therapists": [
      {
        "id": "cuid",
        "firstName": "Dr. Fatima",
        "lastName": "Hassan",
        "bio": "Specialist in spiritual wellness and anxiety.",
        "specialisations": ["anxiety", "spiritual wellness"],
        "languagesSpoken": ["English", "Arabic"],
        "yearsExperience": 8,
        "sessionRateNgn": 15000,
        "averageRating": 4.8,
        "totalSessions": 120,
        "avatarUrl": "https://supabase.co/storage/..."
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 14 }
  }
}
```

### GET /api/v1/therapists/:therapistProfileId
Returns a single therapist's full profile.

### POST /api/v1/therapists/profile
Role: therapist only. Create or update own profile.

Request:
```json
{
  "bio": "...",
  "specialisations": ["grief", "anxiety"],
  "qualifications": ["MSc Psychology"],
  "yearsExperience": 5,
  "languagesSpoken": ["English"],
  "sessionRateNgn": 12000
}
```

---

## Calling — /api/v1/calls

### POST /api/v1/calls/token
Subscription guard: paid tier only.
Rate limited: 5/minute per user.

Request:
```json
{ "therapistProfileId": "cuid" }
```

Response 200:
```json
{
  "success": true,
  "data": {
    "sessionId": "cuid",
    "channelName": "noor_clx8abc123",
    "agoraToken": "006...",
    "agoraAppId": "abc123"
  }
}
```

### POST /api/v1/calls/:sessionId/end
Auth required. Called by either party when the call ends.

Response 200:
```json
{
  "success": true,
  "data": { "sessionId": "cuid", "durationSeconds": 1847 }
}
```

### POST /api/v1/calls/:sessionId/rate
Role: user only. Rate a completed session.

Request:
```json
{ "rating": 5, "comment": "Very helpful." }
```

Response 200:
```json
{ "success": true, "data": { "message": "Rating submitted." } }
```

---

## Payments — /api/v1/payments

### POST /api/v1/payments/subscribe-init
Called by the Netlify subscribe page (not Flutter directly).
No auth header — authenticated via the signed token in the request body.

Request:
```json
{ "token": "signed-jwt-from-app...", "plan": "paid" }
```

Response 200:
```json
{
  "success": true,
  "data": {
    "email": "user@example.com",
    "amountInKobo": 500000,
    "reference": "NR-uuid",
    "userId": "cuid"
  }
}
```

### POST /api/v1/payments/webhook
No auth. Verified via Paystack HMAC signature header.
Always responds 200 to prevent Paystack retries.

Headers: x-paystack-signature: hmac-sha512-hash
Body: Paystack webhook event (raw JSON — do not parse before verifying)

Response 200:
```json
{ "received": true }
```

---

## Streaks — /api/v1/streaks

### GET /api/v1/streaks/me
Returns the user's streak data.

Response 200:
```json
{
  "success": true,
  "data": {
    "currentStreak": 7,
    "longestStreak": 14,
    "totalDays": 31,
    "lastEngagedAt": "2025-04-22T08:00:00Z"
  }
}
```

---

## Notifications — /api/v1/notifications

### GET /api/v1/notifications
Query: ?unreadOnly=true&page=1&limit=20

Response 200:
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "cuid",
        "type": "subscription_active",
        "title": "Subscription Active",
        "body": "Welcome to Noor Companion Premium.",
        "isRead": false,
        "data": null,
        "createdAt": "2025-04-22T14:00:00Z"
      }
    ],
    "unreadCount": 3
  }
}
```

### POST /api/v1/notifications/read-all
Marks all notifications as read.

Response 200:
```json
{ "success": true, "data": { "message": "All notifications marked as read." } }
```

---

## Admin — /api/v1/admin

All routes: Auth required + role = admin.

### GET /api/v1/admin/analytics
Response 200:
```json
{
  "success": true,
  "data": {
    "totalUsers": 1240,
    "activeToday": 312,
    "paidSubscribers": 88,
    "totalTherapists": 14,
    "pendingTherapists": 3,
    "callSessionsThisMonth": 204
  }
}
```

### GET /api/v1/admin/users
Query: ?role=user&subscriptionTier=paid&search=amina&page=1&limit=20

### GET /api/v1/admin/users/:userId

### PATCH /api/v1/admin/users/:userId
```json
{ "isActive": false, "subscriptionTier": "paid" }
```

### GET /api/v1/admin/therapists/pending
Returns therapists with status = pending.

### POST /api/v1/admin/therapists/:therapistProfileId/approve
Sets status to active. Sends push notification and email to therapist.

### POST /api/v1/admin/therapists/:therapistProfileId/reject
```json
{ "reason": "Insufficient qualifications provided." }
```

### POST /api/v1/admin/content
Create a new content item (dhikr, dua, recitation).

```json
{
  "title": "Subhanallah",
  "arabicText": "سُبْحَانَ اللَّهِ",
  "transliteration": "SubhanAllah",
  "translation": "Glory be to Allah",
  "audioUrl": "https://supabase.co/storage/...",
  "category": "dhikr",
  "tags": ["morning", "general"]
}
```

### PATCH /api/v1/admin/content/:contentId
Toggle isActive, update fields.

### POST /api/v1/admin/notifications/broadcast
```json
{
  "title": "New Content Available",
  "body": "New evening adhkar added.",
  "targetRole": "user"
}
```

---

## Health Check

### GET /health
No auth.

Response 200:
```json
{ "status": "ok", "timestamp": "2025-04-22T12:00:00Z" }
```

---

## Error Codes

| Code                  | HTTP | Meaning                                      |
|-----------------------|------|----------------------------------------------|
| VALIDATION_ERROR      | 400  | Zod validation failed — fields included      |
| UNAUTHORIZED          | 401  | Missing, invalid, or expired Supabase token  |
| FORBIDDEN             | 403  | Authenticated but wrong role                 |
| SUBSCRIPTION_REQUIRED | 403  | Feature needs paid subscription              |
| NOT_FOUND             | 404  | Resource does not exist                      |
| CONFLICT              | 409  | Resource already exists (e.g. profile)       |
| RATE_LIMITED          | 429  | Too many requests                            |
| INTERNAL_ERROR        | 500  | Unhandled server error (logged to Sentry)    |
