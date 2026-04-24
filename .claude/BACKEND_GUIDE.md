# BACKEND_GUIDE.md — Noor Companion
# Node.js conventions, patterns, and code templates for the backend.
# Read this before writing any backend code.

## Key Difference: No Custom Auth

This project uses Supabase Auth. The backend does NOT:
- Hash passwords
- Generate JWTs
- Store refresh tokens
- Build login or register endpoints

All of that is handled by Supabase. The backend's auth middleware simply
calls supabase.auth.getUser(token) to verify the Supabase access token and
identify the user. Login and registration happen in Flutter via supabase_flutter.

---

## Auth Middleware

```javascript
/**
 * Authentication middleware.
 * Verifies the Supabase access token from the Authorization header.
 * On success, attaches the full user record to req.user.
 * On failure, returns 401.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'No token provided.' },
      });
    }

    const token = authHeader.split(' ')[1];

    // Verify the token with Supabase — this is the only verification needed
    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(token);

    if (error || !supabaseUser) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token.' },
      });
    }

    // Fetch our app user record that mirrors the Supabase user
    const appUser = await prisma.user.findUnique({
      where: { supabaseId: supabaseUser.id },
      select: {
        id: true,
        supabaseId: true,
        firstName: true,
        lastName: true,
        role: true,
        subscriptionTier: true,
        isActive: true,
        fcmToken: true,
      },
    });

    if (!appUser || !appUser.isActive) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Account not found or suspended.' },
      });
    }

    req.user = appUser;
    next();
  } catch (error) {
    next(error);
  }
}
```

---

## Full Route Pattern

Every route follows: validator → service → controller → route registration.

### 1. Validator (src/validators/therapists.validator.js)

```javascript
/**
 * Zod validation schemas for therapist routes.
 * Import these via the validate() middleware factory.
 */

const { z } = require('zod');

/**
 * Schema for creating or updating a therapist profile.
 * All fields are required on creation. All fields are optional on update.
 */
const therapistProfileSchema = z.object({
  bio: z.string().min(50, 'Bio must be at least 50 characters').max(1000),
  specialisations: z.array(z.string()).min(1, 'At least one specialisation required'),
  qualifications: z.array(z.string()).min(1, 'At least one qualification required'),
  yearsExperience: z.number().int().min(0).max(50),
  languagesSpoken: z.array(z.string()).min(1),
  sessionRateNgn: z.number().int().min(0),
});

module.exports = { therapistProfileSchema };
```

### 2. Service (src/services/therapists.service.js)

```javascript
/**
 * Therapist service — all business logic for therapist-related operations.
 * Called by the therapist controller. Never called directly from routes.
 *
 * Dependencies: Prisma (database), Redis (cache), notificationService (push)
 */

const { prisma } = require('../config/prisma');
const { redis } = require('../config/redis');

const THERAPIST_LIST_CACHE_KEY = 'therapists:active';
const THERAPIST_CACHE_TTL = 300; // 5 minutes

/**
 * Returns all active therapists with their aggregate rating.
 * Results are cached in Redis for 5 minutes.
 *
 * @param {{ specialisation?: string, language?: string, page: number, limit: number }} filters
 * @returns {Promise<{ therapists: object[], total: number }>}
 */
async function getActiveTherapists(filters) {
  const { specialisation, language, page, limit } = filters;
  const offset = (page - 1) * limit;

  // Build dynamic Prisma where clause based on filters
  const whereClause = {
    status: 'active',
    ...(specialisation && { specialisations: { has: specialisation } }),
    ...(language && { languagesSpoken: { has: language } }),
  };

  const [therapists, total] = await prisma.$transaction([
    prisma.therapistProfile.findMany({
      where: whereClause,
      include: {
        user: {
          select: { firstName: true, lastName: true, avatarUrl: true },
        },
        ratings: {
          select: { rating: true },
        },
      },
      skip: offset,
      take: limit,
      orderBy: { approvedAt: 'desc' },
    }),
    prisma.therapistProfile.count({ where: whereClause }),
  ]);

  // Flatten and compute average rating for each therapist
  const formatted = therapists.map((profile) => {
    const totalRating = profile.ratings.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = profile.ratings.length > 0
      ? Math.round((totalRating / profile.ratings.length) * 10) / 10
      : null;

    return {
      id: profile.id,
      firstName: profile.user.firstName,
      lastName: profile.user.lastName,
      avatarUrl: profile.user.avatarUrl,
      bio: profile.bio,
      specialisations: profile.specialisations,
      languagesSpoken: profile.languagesSpoken,
      yearsExperience: profile.yearsExperience,
      sessionRateNgn: profile.sessionRateNgn,
      averageRating,
      totalSessions: profile.ratings.length,
    };
  });

  return { therapists: formatted, total };
}

module.exports = { getActiveTherapists };
```

### 3. Controller (src/controllers/therapists.controller.js)

```javascript
/**
 * Therapist controller — thin layer between routes and therapist service.
 * Receives validated request data, calls services, returns responses.
 * Contains no business logic.
 */

const therapistService = require('../services/therapists.service');

/**
 * GET /api/v1/therapists
 * Returns paginated list of active therapists.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
async function listTherapists(req, res, next) {
  try {
    const { specialisation, language, page = 1, limit = 20 } = req.query;

    const result = await therapistService.getActiveTherapists({
      specialisation,
      language,
      page: Number(page),
      limit: Number(limit),
    });

    return res.json({
      success: true,
      data: {
        therapists: result.therapists,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total: result.total,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { listTherapists };
```

### 4. Route (src/routes/therapists.routes.js)

```javascript
/**
 * Therapist routes — /api/v1/therapists
 * All routes require JWT authentication.
 */

const { Router } = require('express');
const { listTherapists, getTherapist, upsertProfile } = require('../controllers/therapists.controller');
const { authenticate } = require('../middleware/auth');
const { roleGuard } = require('../middleware/roleGuard');
const { validate } = require('../middleware/validate');
const { therapistProfileSchema } = require('../validators/therapists.validator');

const router = Router();

// All therapist routes require authentication
router.use(authenticate);

router.get('/', listTherapists);
router.get('/:therapistProfileId', getTherapist);
router.post('/profile', roleGuard('therapist'), validate(therapistProfileSchema), upsertProfile);

module.exports = router;
```

---

## Config Files

### config/supabase.js

```javascript
/**
 * Supabase admin client — uses the service role key.
 * This client bypasses Row Level Security and has full database access.
 * Used only in the backend, never exposed to the client.
 * Used for: token verification, user metadata updates, auth admin operations.
 */

const { createClient } = require('@supabase/supabase-js');
const { env } = require('./env');

const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

module.exports = { supabase };
```

### config/prisma.js

```javascript
/**
 * Prisma client singleton.
 * Reuses the same instance across the application to avoid connection exhaustion.
 * In development, attaches to the global object to survive hot reloads.
 */

const { PrismaClient } = require('@prisma/client');

const globalForPrisma = globalThis;

const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

module.exports = { prisma };
```

### config/env.js

```javascript
/**
 * Validated environment configuration using Zod.
 * The server will refuse to start if any required variable is missing.
 * This prevents silent failures in production.
 */

const { z } = require('zod');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().url(),
  DIRECT_DATABASE_URL: z.string().url(),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  SUBSCRIPTION_TOKEN_SECRET: z.string().min(32),
  UPSTASH_REDIS_URL: z.string().url(),
  PAYSTACK_SECRET_KEY: z.string().min(1),
  AGORA_APP_ID: z.string().min(1),
  AGORA_APP_CERTIFICATE: z.string().min(1),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIREBASE_PRIVATE_KEY: z.string().min(1),
  FIREBASE_CLIENT_EMAIL: z.string().email(),
  RESEND_API_KEY: z.string().min(1),
  FROM_EMAIL: z.string().email(),
  SENTRY_DSN: z.string().url(),
  WEBSITE_URL: z.string().url(),
});

const env = envSchema.parse(process.env);
module.exports = { env };
```

---

## Validate Middleware

```javascript
/**
 * Middleware factory that validates req.body against a Zod schema.
 * Returns 400 with field-level errors on failure.
 * Replaces req.body with the parsed (typed) data on success.
 *
 * @param {import('zod').ZodSchema} schema
 * @returns {import('express').RequestHandler}
 */
function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request data.',
          fields: result.error.flatten().fieldErrors,
        },
      });
    }

    req.body = result.data;
    next();
  };
}
```

---

## Error Handler

```javascript
/**
 * Global error handler — must be the last middleware registered in app.js.
 * Formats all errors into the standard API error shape.
 * Errors thrown with .statusCode and .code are handled gracefully.
 * All other errors are treated as 500 internal errors.
 */
function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  const code = err.code || 'INTERNAL_ERROR';

  // For 500s, the message is generic to avoid leaking internals
  const message = statusCode >= 500
    ? 'An unexpected error occurred.'
    : err.message;

  if (statusCode >= 500) {
    req.log.error({ err }, 'Internal server error');
  }

  return res.status(statusCode).json({
    success: false,
    error: { code, message },
  });
}
```

---

## Redis Cache Pattern

```javascript
/**
 * Generic cache-or-fetch helper.
 * Returns cached value if present, otherwise fetches and caches.
 *
 * @param {string} key - Redis cache key
 * @param {number} ttlSeconds - Cache TTL in seconds
 * @param {Function} fetchFn - Async function that fetches fresh data
 * @returns {Promise<any>} Parsed cached or fresh data
 */
async function cacheOrFetch(key, ttlSeconds, fetchFn) {
  const cached = await redis.get(key);

  if (cached) {
    return JSON.parse(cached);
  }

  const fresh = await fetchFn();
  await redis.setex(key, ttlSeconds, JSON.stringify(fresh));
  return fresh;
}
```

---

## Prisma Query Rules

Always use select to specify exactly which fields you need.
Never return the full record if only a subset is needed.

```javascript
// CORRECT — explicit selection
const user = await prisma.user.findUnique({
  where: { id: userId },
  select: {
    id: true,
    firstName: true,
    role: true,
    subscriptionTier: true,
  },
});

// WRONG — returns all fields, wastes bandwidth, risks leaking data
const user = await prisma.user.findUnique({ where: { id: userId } });
```
