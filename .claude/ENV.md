# ENV.md — Noor Companion
# Every environment variable for the backend and Flutter.
# Never commit actual values to git. Never log these values.

## Backend — .env.example

```env
# ─── Application ──────────────────────────────────────────
NODE_ENV=development
PORT=3000

# ─── Supabase ─────────────────────────────────────────────
SUPABASE_URL=https://your-project-ref.supabase.co
# Get from: Supabase dashboard → Project Settings → API → Project URL

SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
# Get from: Supabase dashboard → Project Settings → API → service_role key
# WARNING: This key bypasses RLS. Never expose it to clients.

DATABASE_URL=postgresql://postgres.[project-ref]:[password]@aws-0-eu-west-2.pooler.supabase.com:6543/postgres?pgbouncer=true
# Pooled connection — use this for the running app (PgBouncer on port 6543)
# Get from: Supabase dashboard → Project Settings → Database → Connection string → URI
# Append: ?pgbouncer=true

DIRECT_DATABASE_URL=postgresql://postgres.[project-ref]:[password]@aws-0-eu-west-2.pooler.supabase.com:5432/postgres
# Direct connection — use this for Prisma migrations only (port 5432)
# Get from same location, remove pgbouncer param

# ─── Upstash Redis ─────────────────────────────────────────
UPSTASH_REDIS_URL=rediss://default:[password]@[hostname].upstash.io:6379
# Get from: Upstash dashboard → your database → Connect → ioredis

# ─── Payments (Paystack) ──────────────────────────────────
PAYSTACK_SECRET_KEY=sk_live_...
# Use sk_test_... for development
# Get from: Paystack dashboard → Settings → API Keys & Webhooks

SUBSCRIPTION_TOKEN_SECRET=replace-with-64-random-hex-chars
# Used to sign the short-lived iOS payment redirect tokens
# Generate: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# ─── Agora ────────────────────────────────────────────────
AGORA_APP_ID=your-32-char-hex-app-id
# Get from: Agora Console → your project → App ID

AGORA_APP_CERTIFICATE=your-32-char-hex-certificate
# Get from: Agora Console → your project → App Certificate
# IMPORTANT: Enable App Certificate in the console first (disabled by default)

# ─── Firebase (Push Notifications) ────────────────────────
FIREBASE_PROJECT_ID=noor-companion-xxxxx
# Get from: Firebase Console → Project Settings → General

FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
# Get from: Firebase Console → Project Settings → Service Accounts
# → Generate new private key → copy private_key from downloaded JSON
# Keep the \n literal newlines in the env var value

FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@noor-companion-xxxxx.iam.gserviceaccount.com
# Get from the same downloaded JSON — client_email field

# ─── Email (Resend) ────────────────────────────────────────
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Get from: resend.com → API Keys

FROM_EMAIL=noreply@noorcompanion.com
# Must be a verified domain in your Resend account

# ─── Error Monitoring (Sentry) ────────────────────────────
SENTRY_DSN=https://xxxxxxxxxxxxxxxxxxxxxxxx@o0.ingest.sentry.io/0
# Get from: sentry.io → your project → Settings → Client Keys (DSN)

# ─── Website ───────────────────────────────────────────────
WEBSITE_URL=https://noorcompanion.netlify.app
# In development: http://localhost:5000
# Used to construct the iOS payment redirect URL
```

## Flutter — dart-define Build Flags

Flutter does not use .env files. All config is compiled in at build time
via --dart-define. Never hardcode these values in Dart source files.

```bash
# Development build
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=SUPABASE_URL=https://your-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=AGORA_APP_ID=your-app-id \
  --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/0 \
  --dart-define=WEBSITE_URL=http://localhost:5000 \
  --dart-define=ENVIRONMENT=development

# Production Android build
flutter build apk \
  --dart-define=API_BASE_URL=https://api.noorcompanion.com/api/v1 \
  --dart-define=SUPABASE_URL=https://your-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=AGORA_APP_ID=your-app-id \
  --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/0 \
  --dart-define=WEBSITE_URL=https://noorcompanion.netlify.app \
  --dart-define=ENVIRONMENT=production

# Production iOS build
flutter build ipa \
  --dart-define=API_BASE_URL=https://api.noorcompanion.com/api/v1 \
  --dart-define=SUPABASE_URL=https://your-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=AGORA_APP_ID=your-app-id \
  --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/0 \
  --dart-define=WEBSITE_URL=https://noorcompanion.netlify.app \
  --dart-define=ENVIRONMENT=production
```

## Supabase Setup Checklist

Before starting development:

- [ ] Create Supabase project at supabase.com
- [ ] Note Project URL and anon key (for Flutter)
- [ ] Note service_role key (for backend — keep secret)
- [ ] Get both DATABASE_URL (pooled) and DIRECT_DATABASE_URL (direct)
- [ ] Create storage bucket: avatars (public)
- [ ] Create storage bucket: content-audio (public)
- [ ] Enable Email auth provider in Supabase Auth settings
- [ ] Set Site URL in Supabase Auth: https://noorcompanion.netlify.app
- [ ] Add redirect URLs: noorcompanion://auth-callback (for deep linking)

## Render Setup Checklist (Backend)

- [ ] Create Web Service pointing to backend/ folder
- [ ] Build command: npm install && npx prisma generate && npx prisma migrate deploy
- [ ] Start command: node src/server.js
- [ ] Add all .env variables from the list above
- [ ] Add health check path: /health
- [ ] Upgrade to Starter ($7/mo) to prevent spin-down

## Netlify Setup Checklist (Website)

- [ ] Connect git repo, set publish directory to website/
- [ ] No build command needed (static files)
- [ ] Set custom domain if available
- [ ] Verify HTTPS is active

## Pre-Production Security Checklist

- [ ] No .env file committed to git (.gitignore covers it)
- [ ] PAYSTACK_SECRET_KEY uses sk_live_ prefix
- [ ] AGORA_APP_CERTIFICATE is enabled in Agora console
- [ ] SUPABASE_SERVICE_ROLE_KEY is only in the backend — never in Flutter
- [ ] SUPABASE_ANON_KEY is in Flutter — this is safe (it is public by design)
- [ ] SENTRY_DSN points to production Sentry project
- [ ] WEBSITE_URL is the live Netlify URL
