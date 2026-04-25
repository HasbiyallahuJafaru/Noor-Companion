# Build Tasks: Recovery Companion (Core Mobile App)

Generated from: .design/recovery-companion/DESIGN_BRIEF.md
Date: 2026-04-25

All tasks are Flutter (Dart). No mobile code exists yet — every task creates
new files. Aesthetic philosophy: Sacred Minimalism. Teal #0D7C6E primary,
Gold #C9933A accent, off-white #F6FAF9 background.

---

## Foundation

- [ ] **Flutter project scaffold**: Initialise the Flutter project at `mobile/`
  with `flutter create`. Add core dependencies to `pubspec.yaml`:
  `supabase_flutter`, `flutter_riverpod`, `go_router`, `dio`, `hive`,
  `google_fonts`, `agora_rtc_engine`, `firebase_messaging`, `sentry_flutter`,
  `url_launcher`, `vibration`. Done when `flutter run` shows a blank screen
  with no errors. _New project._

- [ ] **Design tokens — `app_theme.dart`**: Create
  `lib/core/theme/app_theme.dart` defining `AppColors` (all hex values from
  brief), `AppRadius`, `AppShadows`, and `AppTextStyles` (Inter for Latin,
  Amiri for Arabic via `google_fonts`). Wire into `MaterialApp` as the root
  `ThemeData`. Done when colours and fonts render correctly on a blank screen.
  _New file. This is the visual foundation — build nothing else until this is
  verified._

- [ ] **App shell — bottom navigation**: Build `lib/core/shell/app_shell.dart`
  — a `StatefulWidget` with a `BottomNavigationBar` (4 tabs: Home, Tasks,
  Progress, Therapists). Each tab renders a placeholder screen. Navigation
  persists state across tab switches. Done when tapping all 4 tabs switches
  content without rebuilding the shell. _New component. Depends on:
  app_theme.dart._

- [ ] **GoRouter setup**: Configure `lib/core/router/app_router.dart` with
  named routes for all screens: `/`, `/onboarding`, `/home`, `/tasks`,
  `/progress`, `/therapists`, `/therapist/:id`, `/call/:sessionId`,
  `/milestone/:badge`. Wire the router into `MaterialApp.router`. Done when
  navigating to each route by name renders the correct placeholder. _New file.
  Depends on: app shell._

- [ ] **Riverpod providers scaffold**: Create
  `lib/core/providers/user_provider.dart` (current user + subscription tier),
  `streak_provider.dart` (days clean counter), and `tasks_provider.dart`
  (today's task list). These hold stub data for now — real API calls come
  later. Done when providers can be read in any screen without errors. _New
  files._

---

## Onboarding Flow

- [ ] **Onboarding screen 1 — Addiction type**: Build
  `lib/features/onboarding/screens/onboarding_addiction_screen.dart`. Four
  large selection cards (Alcohol / Drugs / Prescription medication / Prefer
  not to say) + a "Skip" text link at the bottom. Teal-bordered selected
  state. Saves choice to Hive local storage. "Continue" button activates after
  a selection or skip. Done when selection persists after hot restart. _New
  screen._

- [ ] **Onboarding screen 2 — Journey stage**: Build
  `lib/features/onboarding/screens/onboarding_stage_screen.dart`. Four
  selection cards (Just starting / A few weeks / A few months / Over a year).
  Same card pattern as screen 1. Saves to Hive. Done when all states render
  and selection is stored. _New screen. Reuses: selection card pattern from
  screen 1._

- [ ] **Onboarding screen 3 — Therapist preference**: Build
  `lib/features/onboarding/screens/onboarding_therapist_screen.dart`. Two
  large option cards (Yes, connect me / Maybe later). Below the cards, a
  single line: "Licensed counsellors and Islamic scholars available on demand."
  in muted teal. On confirm → navigate to home. Done when choosing either
  option routes correctly. _New screen._

---

## Home Screen

- [ ] **Home screen layout**: Build `lib/features/home/screens/home_screen.dart`.
  Layout from top: greeting (user's name or "Assalamu Alaikum"), streak
  display widget, today's task list (max 3 tasks), and at the bottom fixed
  above the nav bar — the "I'm Struggling" button. The streak display and
  tasks scroll; the button does not. Done when the button is always visible on
  the smallest supported screen (375pt) without scrolling. _New screen.
  Depends on: streak_provider, tasks_provider._

- [ ] **Streak display widget**: Build
  `lib/features/home/widgets/streak_display.dart`. Shows a large number (days
  clean), the label "days of clarity", and a subtle teal progress arc around
  it. Reads from `streak_provider`. On milestone days (7, 30, 90, 180, 365)
  shows a gold glow. Done when the widget renders with stub data at 0, 7, and
  30 days showing correct states. _New widget._

- [ ] **"I'm Struggling" panic button**: Build
  `lib/features/home/widgets/panic_button.dart`. Full-width, 64pt tall, teal
  background, white bold text "I'm Struggling". Subtle pulsing animation
  (scale 1.0 → 1.015 → 1.0, 2s loop) to draw attention without being alarming.
  Tap → navigate to intervention flow. Done when animation runs smoothly at
  60fps and tap registers instantly with no delay. _New widget._

- [ ] **Daily task card**: Build
  `lib/features/home/widgets/task_card.dart`. Shows task name, estimated time
  badge, and a large circular checkbox on the right. Completed state: teal
  fill, checkmark, task name struck through. Tap to toggle completion updates
  `tasks_provider`. Done when checking a task persists across screen
  navigation. _New widget._

- [ ] **Prayer time banner**: Build
  `lib/features/home/widgets/prayer_time_banner.dart`. A slim strip (40pt
  tall) below the greeting showing next prayer name and countdown. Teal-light
  background, teal text. Taps open the system clock app (no in-app prayer
  tracker). Done when the strip is visible and non-intrusive on the home
  layout. _New widget. Stub data only in this task — real prayer times wired
  in a later task._

---

## Arabic Text & Dhikr

- [ ] **Arabic text display block**: Build
  `lib/shared/widgets/arabic_text_block.dart`. Accepts `arabic`, `transliteration`,
  and `translation` strings. Arabic in Amiri 28sp, centred, RTL. Transliteration
  in Inter italic 14sp, teal-light colour. Translation in Inter 15sp, dark text.
  Generous vertical padding between each layer. Done when all three layers
  render correctly with a sample dua and the Arabic text is visually prominent.
  _New shared widget. This block is used in 4+ screens — verify it before
  those screens are built._

- [ ] **Dhikr counter widget**: Build
  `lib/features/tasks/widgets/dhikr_counter.dart`. Large circular button (80pt
  diameter) showing current count and target (e.g., "33 / 33"). Each tap:
  increments count, triggers `HapticFeedback.mediumImpact()`, plays a
  subtle tick sound. On completion: button turns gold, shows checkmark, plays
  a soft chime. Resets button appears below on completion. Done when 33 rapid
  taps register correctly with no dropped inputs and haptics fire on device.
  _New widget._

---

## Crisis Intervention Flow

- [ ] **Intervention screen 1 — Dua**: Build
  `lib/features/intervention/screens/intervention_dua_screen.dart`. Full-screen
  teal-gradient background (very subtle, #0D7C6E 5% to transparent). Shows the
  `ArabicTextBlock` for a hardcoded short dua (A'udhu billahi min al-shaytani
  r-rajim). "Continue" button appears after 10 seconds (countdown visible as a
  thin progress line at the bottom). Done when the timer fires correctly and
  the Continue button appears. _New screen. Reuses: ArabicTextBlock._

- [ ] **Intervention screen 2 — Breathing exercise**: Build
  `lib/features/intervention/screens/intervention_breathing_screen.dart`.
  Animated circle: expand over 4s (inhale label), hold 4s (hold label),
  contract 4s (exhale label). Runs 3 full cycles then auto-advances. "Skip"
  text link top-right available throughout. Animation uses
  `AnimationController` respecting `MediaQuery.disableAnimations` for
  accessibility. Done when 3 complete cycles auto-advance to screen 3 and
  Skip works at any point. _New screen._

- [ ] **Intervention screen 3 — Physical task**: Build
  `lib/features/intervention/screens/intervention_task_screen.dart`. Randomly
  selects one task from the task pool (hardcoded list for now). Displays task
  name large, a brief instruction, and a large "I did it" button. If task is
  a timed walk, shows a 5-minute countdown timer. Done when random selection
  works across 5+ taps and the timer counts correctly. _New screen._

- [ ] **Intervention screen 4 — Affirmation**: Build
  `lib/features/intervention/screens/intervention_affirm_screen.dart`. Shows
  "You're doing well. That took strength." in large Inter text with generous
  line height. Below: two options — "Call a Therapist" (teal button) and
  "Return Home" (ghost button). "Call a Therapist" navigates to the Therapists
  tab. "Return Home" pops the intervention stack entirely. Done when both
  buttons navigate correctly without leaving orphaned routes on the stack. _New
  screen._

- [ ] **Intervention flow controller**: Build
  `lib/features/intervention/intervention_flow.dart`. A `PageView` or
  sequential navigator that owns the 4-screen sequence. Triggered from the
  panic button. Handles back-press suppression (user cannot accidentally swipe
  back mid-sequence). Tracks completion — if all 4 screens are completed,
  increments a daily "interventions handled" counter in Riverpod. Done when
  the full 4-screen sequence runs without routing bugs. _New controller.
  Depends on: all 4 intervention screens._

---

## Therapists Tab

- [ ] **Therapist profile card**: Build
  `lib/features/therapists/widgets/therapist_card.dart`. Shows circular avatar
  (80pt), therapist name, specialty tag ("Licensed Counsellor" or "Islamic
  Scholar"), and an availability dot (green = available, grey = offline). Tap
  navigates to the therapist detail screen. Done when both specialty types
  render correctly and the availability dot shows both states. _New widget._

- [ ] **Therapists list screen**: Build
  `lib/features/therapists/screens/therapists_screen.dart`. Scrollable list
  of `TherapistCard` widgets. Two section headers: "Counsellors" and "Islamic
  Scholars". Stub data with 3 therapists per section. Search bar at top (client-
  side filter only in this task). Done when filtering by name works on stub
  data. _New screen. Reuses: TherapistCard._

- [ ] **Therapist detail screen**: Build
  `lib/features/therapists/screens/therapist_detail_screen.dart`. Full profile:
  large avatar, name, specialty, short bio (2–3 sentences), availability
  status. A full-width "Call Now" button at the bottom — enabled only when
  therapist is available, disabled with "Not available right now" when offline.
  Done when both enabled and disabled states render correctly. _New screen._

---

## Audio Call

- [ ] **Call screen**: Build `lib/features/call/screens/call_screen.dart`. Full-
  screen dark teal background. Centre: therapist avatar and name. Bottom row:
  mute toggle (microphone icon) and end call (red circle). Call duration timer
  top-right. Speaker toggle top-left. All buttons minimum 56pt tap target with
  semantic labels for screen readers. Done when all 4 buttons render with
  correct labels and mute/end emit the right events (stub — no Agora connected
  yet). _New screen._

- [ ] **Agora RTC integration**: Wire `agora_rtc_engine` into the call screen.
  Fetch an Agora token from `POST /api/v1/calls/token`. Join the channel. Mute
  toggles local audio. End call leaves the channel and calls
  `POST /api/v1/calls/:sessionId/end`. On call end → show a rating prompt
  (1–5 stars, optional). Done when a real audio call connects between two
  devices on the same channel. _Modifies: call_screen.dart. Depends on:
  backend call token endpoint._

---

## Progress Tab

- [ ] **Progress screen**: Build
  `lib/features/progress/screens/progress_screen.dart`. Three sections: streak
  summary (reads from `streak_provider`), weekly task completion bar chart
  (7 bars, one per day, teal fill), and earned badges grid. Stub data for
  chart and badges. Done when all three sections render without overflow on
  375pt width. _New screen._

- [ ] **Milestone badge component**: Build
  `lib/features/progress/widgets/milestone_badge.dart`. Circular badge 72pt
  diameter. Locked state: grey fill, lock icon. Unlocked state: gold fill,
  Arabic virtue name (e.g., صبر "Sabr") centred, soft gold glow shadow. Tap
  on unlocked badge navigates to the milestone detail screen. Done when both
  locked and unlocked states render at all 5 milestone levels. _New widget._

- [ ] **Milestone detail screen**: Build
  `lib/features/progress/screens/milestone_screen.dart`. Full-screen
  congratulatory view: badge large (120pt), virtue name in Arabic + English,
  an ayah related to patience/tawbah (uses `ArabicTextBlock`), and a "Continue"
  button returning home. Done when all 5 milestone variants render correctly
  with their respective ayaat. _New screen. Reuses: ArabicTextBlock,
  MilestageBadge._

---

## Interactions & States

- [ ] **Relapse / streak reset flow**: Build
  `lib/features/home/screens/return_screen.dart`. Triggered when a user
  manually resets their streak (a "I relapsed" option accessible from the
  streak widget — not prominent, but findable). Never resets coldly. Shows:
  "Tawbah is always open." + an ayah on repentance + `ArabicTextBlock` +
  "Start again" button that resets the streak counter to 0 and navigates home.
  Done when streak resets to 0 and the warm message is shown before returning.
  _New screen. Reuses: ArabicTextBlock._

- [ ] **Empty and loading states**: Add loading skeletons (teal-tinted shimmer)
  and empty states to: therapists list (no results), progress chart (no data
  yet — "Your journey starts today"), task list (all done — "Masha'Allah,
  you're done for today"). Done when all three empty states render without
  layout breaks. _Modifies: therapists_screen, progress_screen, home_screen._

---

## Notifications & Background

- [ ] **Firebase push notifications**: Wire `firebase_messaging` for foreground
  and background. Handle notification types: `morning_reminder`,
  `evening_reflection`, `task_reminder`, `therapist_available`,
  `milestone_unlocked`. Each type routes to the correct screen on tap. Done
  when a test notification sent from Firebase console navigates the app
  correctly. _New file: `lib/core/notifications/notification_handler.dart`._

---

## Polish & Accessibility

- [ ] **Accessibility pass**: Across all screens — add `Semantics` wrappers to
  all icon-only buttons (call controls, dhikr counter, close buttons). Verify
  Arabic text blocks have a combined `semanticsLabel` that reads the English
  translation (not the Arabic). Verify `MediaQuery.disableAnimations` is
  respected in the breathing exercise and panic button pulse. Test minimum tap
  targets (44pt) on all interactive elements. _Modifies: all screens._

- [ ] **Haptics and micro-interactions**: Add `HapticFeedback.lightImpact()` to
  task card completion, selection cards in onboarding, and milestone unlock.
  Add `HapticFeedback.mediumImpact()` to dhikr counter taps. Add a soft
  success chime (`AudioPlayer`) to milestone unlock and dhikr completion. Done
  when all haptics fire on a physical device. _Modifies: task_card, dhikr_counter,
  onboarding screens, milestone_screen._

---

## Review

- [ ] **Design review**: Run `/design-review` against the brief once all Core UI
  and Interactions tasks are complete.
