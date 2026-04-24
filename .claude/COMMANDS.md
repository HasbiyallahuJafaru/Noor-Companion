# COMMANDS.md — Noor Companion
# Slash commands for Claude Code sessions.
# Run these to trigger predefined workflows.

---

## /start
Run at the beginning of every session.

1. Read CLAUDE.md
2. Read PHASES.md — identify current phase, read its section
3. Run graphify
4. Run: git log --oneline -10
5. Run: grep -r "TODO:" --include="*.js" --include="*.dart" . | head -20
6. Confirm the first file to work on today

---

## /build-backend-route [routeName]
Scaffold a complete backend route following the BACKEND_GUIDE pattern.

1. Create src/validators/[routeName].validator.js — Zod schemas
2. Create src/services/[routeName].service.js — business logic stubs with JSDoc
3. Create src/controllers/[routeName].controller.js — thin controller stubs
4. Create src/routes/[routeName].routes.js — route definitions with middleware
5. Register the new route in src/app.js
6. Print a checklist of functions still needing implementation in the service

---

## /build-flutter-feature [featureName]
Scaffold a complete Flutter feature following FLUTTER_GUIDE conventions.

1. Create features/[featureName]/data/[featureName]_repository.dart
2. Create features/[featureName]/domain/models/[model]_model.dart
3. Create features/[featureName]/presentation/providers/[featureName]_provider.dart
4. Create features/[featureName]/presentation/screens/[featureName]_screen.dart
5. Add the route to core/router/app_router.dart
6. Add Dart doc comments to every class and public method
7. Print which API endpoints this feature depends on (from API_CONTRACT.md)

---

## /verify-phase [phaseNumber]
Run through the verification checklist for a completed phase.

1. Read PHASES.md and find the checklist for phase [phaseNumber]
2. Go through every item — test each one
3. Mark items ✅ or ❌ with a note on failures
4. Print a summary: X of Y items passing
5. Only mark the phase complete when all items pass

---

## /check-security
Security audit of the backend codebase.

- [ ] Every route handler (except /health and /payments/webhook) has authenticate middleware
- [ ] Every route handler has validate() middleware with a Zod schema
- [ ] /payments/webhook uses express.raw() not express.json()
- [ ] Paystack webhook HMAC verification runs before any processing
- [ ] Agora token endpoint checks subscriptionTier === 'paid' before generating token
- [ ] No passwordHash or supabaseId exposed in any API response
- [ ] process.env never accessed directly outside config/env.js
- [ ] All catch blocks call Sentry.captureException()
- [ ] Rate limiters applied to /calls/token route

---

## /check-docs
Documentation coverage audit.

Backend:
- [ ] Every .js file in src/ has a file-level header comment
- [ ] Every exported function has JSDoc with @param, @returns, and description
- [ ] No function longer than 50 lines
- [ ] No file longer than 300 lines

Flutter:
- [ ] Every .dart file has a file-level /// comment
- [ ] Every public class and method has a Dart doc comment
- [ ] No function longer than 50 lines
- [ ] No file longer than 300 lines

---

## /check-supabase
Verify Supabase integration is correct.

- [ ] supabase.auth.getUser(token) used in auth middleware (not JWT verification)
- [ ] No custom JWT generation anywhere in the codebase
- [ ] No bcrypt or password hashing in the backend
- [ ] Supabase service role key only in backend config, never in Flutter
- [ ] Supabase anon key in Flutter AppConfig (this is correct — it is public)
- [ ] User.supabaseId correctly linked to Supabase auth.users.id
- [ ] Supabase Storage URLs used for avatarUrl and audioUrl fields

---

## /api-test [routePath]
Generate curl test commands for a specific route.

Output a shell script with:
- Happy path request (expected 2xx)
- Request without auth token (expected 401)
- Request with invalid input (expected 400)
- Request with wrong role (expected 403) if role-restricted
- Instructions to run locally against http://localhost:3000

---

## /summarise-session
Run at the end of every session.

1. List every file created or modified this session
2. List every TODO comment added in today's code
3. State which PHASES.md checklist items were completed
4. Describe what the next session should start with
5. Flag any incomplete error handling or missing Sentry calls
