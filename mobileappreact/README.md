# Noor Companion — React Native

> **Light your way back**

A cross-platform (iOS / Android / web) rebuild of the Noor Companion Flutter app, built with **Expo SDK 57 + Expo Router + React Native 0.86 (New Architecture)**, and a new visual world: **Luminous Ink** — the Soft Luxury brand (teal / gold / ink / lavender porcelain) evolved with a full luminous dark mode, frosted-glass materials, an animated aurora canvas, and spring-physics motion throughout.

## Run it

```bash
npm install
npx expo start
```

Then press `i` (iOS simulator), `a` (Android emulator), or scan the QR with **Expo Go**.

**Demo mode is on by default** (`EXPO_PUBLIC_DEMO_MODE=1`): the entire app runs against realistic fixtures with no backend — auth, streaks, prayer times, therapists, calls (simulated RTC), subscriptions, and the admin panel are all explorable.

- Sign in with any email. Include `admin` or `therapist` in the email to explore those roles (e.g. `admin@demo.com`, `therapist@demo.com`).
- Demo streaks/progress mutate locally so tasbih counters, completions, and milestone flows behave like production.

## Connect to the real platform

Copy `.env.example` to `.env` and set:

| Variable | Purpose |
|---|---|
| `EXPO_PUBLIC_API_BASE_URL` | Railway API base (default `http://localhost:3000/api/v1`) |
| `EXPO_PUBLIC_SUPABASE_URL` | Supabase project URL (auth only) |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
| `EXPO_PUBLIC_WEBSITE_URL` | Payment site for the iOS checkout hand-off |
| `EXPO_PUBLIC_DEMO_MODE` | `0` for production behaviour |

Then `EXPO_PUBLIC_DEMO_MODE=0 npx expo start`. Every endpoint from the Flutter app is implemented in `src/lib/api.ts` with identical paths, payloads, and the `{ data: ... }` response unwrapping — the Railway backend needs zero changes.

## What's inside

```
app/                     Expo Router routes (file-based navigation)
  (auth)/                login, register (fade transitions)
  onboarding/            3-step flow with progress line
  (tabs)/                role-based glass tab bar shell
    index                home: aurora canvas, prayer banner, streak ring,
                         daily dhikr, adhkar rails, explore, panic button
    dhikr / quran / therapists / dashboard / admin / profile
  dhikr/[id]             Arabic block, audio, tasbih counter, milestone gate
  duas/, quran/[surah]   libraries, bookmarks, surah reader + audio
  intervention/          4-step crisis flow: dua → breathing → task → affirm
  therapists/[id]        profile + call CTA (tier-gated)
  call/[sessionId]       animated orb, live timer, mute/speaker/end
  call-rating            star rating + comment
  upgrade                premium paywall, in-app-browser checkout + polling
  progress, milestone/   streak stats, weekly chart, milestone celebrations
  notifications, return  feed with unread badges, tawbah mercy screen
  therapist/, admin/     therapist workspace and platform management
src/
  theme/                 tokens (light+dark), typography, motion language
  components/ui/         Button (shimmer), GlassCard, Sheet, Input, Screen…
  components/core/       AuroraBackground, StreakRing, TasbihCounter,
                         ArabicBlock, WeeklyChart, Confetti, AudioBar…
  lib/                   api client, supabase auth, stores (zustand),
                         react-query hooks, haptics, fixtures (demo mode)
```

## Design system — "Luminous Ink"

- **Light**: lavender porcelain canvas, white glass cards, ink-navy pills, teal `#0D9488` accent, gold `#E8A33D` reserved for streaks/premium.
- **Dark (hero)**: deep ink-navy `#0A0C1A`, luminous teal `#2DD4BF`, gold `#F0B355`, glass surfaces with light-fall borders.
- **Type**: Plus Jakarta Sans (all UI) + Amiri (Arabic, RTL) via `expo-font`.
- **Motion**: spring physics on every pressable (`PressableScale`), staggered list entrances, floating glass tab bar with animated active pill, count-up numerals, shimmer buttons, breathing aurora orbs, confetti on milestones. Haptics layered: light taps → medium completions → heavy milestones.

## Native features requiring a development build

Expo Go covers almost everything, but three features need `npx expo run:android` / `run:ios` (or EAS Build):

1. **Voice calling (Agora)** — call tokens, lifecycle, and rating are fully wired through the API; the RTC engine itself runs in simulated mode. To enable real audio, add `react-native-agora` and implement `AgoraEngine` in `src/lib/calling.ts` (the `CallingEngine` interface is the only seam).
2. **Push notifications (FCM)** — permissions, token registration (`POST /users/me/fcm-token`), and tap routing are wired; device tokens require a dev build.
3. **Background audio** for recitation playback during calls.

## Scripts

| Command | Description |
|---|---|
| `npx expo start` | Dev server (interactive platform picker) |
| `npx expo start --web` | Browser preview |
| `npm run android` / `npm run ios` | Launch on a simulator/emulator |
| `npx tsc --noEmit` | Typecheck (clean) |
| `npx expo export` | Production bundle |

## Notes

- Supabase is auth-only, matching the platform architecture; sessions persist via AsyncStorage and every API call attaches the bearer token, with 401 → global sign-out (same behaviour as the Flutter Dio interceptor).
- The Paystack checkout opens the platform payment page (in-app browser; the backend redirect to `noorcompanion://payment-success` is registered as the app scheme), then polls `/users/me` for the tier flip.
- Streak milestones on the progress arc use `[7, 30, 90, 180, 365]` and live milestones `{7, 14, 30, 100}` — the same constants as the Flutter app.
