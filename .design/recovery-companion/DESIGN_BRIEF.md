# Design Brief: Recovery Companion (Core Mobile App)

## Problem

A person struggling with substance addiction faces their hardest moments alone —
usually late at night, usually in private, usually ashamed. Mainstream recovery
tools feel clinical or secular. Islamic resources exist but are passive (books,
lectures). There is no tool that meets a Muslim in the exact moment of urge,
speaks to them in the language of their faith, keeps their hands and heart busy,
and connects them to a real human when they need one most.

## Solution

A mobile app that acts as a calm, merciful companion for Muslims in recovery.
It conditions the nafs through daily Islamic habit loops — dhikr, dua, physical
tasks, Quran — and delivers positive reinforcement through streaks and milestone
recognition. When an urge strikes, a single button triggers an immediate
intervention sequence. When that's not enough, a live therapist is one tap away.

## Experience Principles

1. **Mercy over judgment** — The app never shames the user for struggling or
   relapsing. Every interaction assumes the user is doing their best and
   returning to Allah is always possible. Copy, prompts, and feedback are
   framed around hope and the next step, never failure.

2. **Occupation over willpower** — The core mechanism is keeping the hands,
   mouth, and mind busy with remembrance. Tasks are not journaling prompts or
   affirmations — they are physical and verbal actions rooted in Sunnah that
   replace the addictive behavior in the moment.

3. **Progressive depth over upfront complexity** — The app reveals itself
   gradually. Day 1 is one button and one dhikr. Week 2 introduces streaks and
   task variety. Month 1 unlocks therapist calling. Nothing overwhelms a user
   who is already in crisis.

## Aesthetic Direction

- **Philosophy**: Sacred Minimalism — the visual language of a premium Islamic
  app combined with the soft, breathing quality of Calm/Headspace. Generous
  whitespace. Subtle organic textures (fine geometric Islamic patterns at very
  low opacity). Nothing loud, nothing clinical.
- **Tone**: Calm, warm, reverent. Like sitting in a quiet masjid at dawn.
  Trustworthy without being cold. Gentle without being weak.
- **Reference points**: Calm app (soft gradients, breathing space, serif type),
  Hallow (faith-first, non-preachy, premium feel), high-end Islamic calligraphy
  apps (Arabic given visual prominence and dignity).
- **Anti-references**: Bright gamified apps (Duolingo energy), clinical white
  health apps, generic productivity trackers, anything that looks like a
  hospital form.

## Existing Patterns

The website design system is the foundation. The mobile app must extend it.

- **Primary**: Teal `#0D7C6E` — calming, trustworthy, the primary action color
- **Accent**: Gold `#C9933A` — warmth, milestone rewards, Islamic aesthetic
- **Background**: Off-white `#F6FAF9` — never pure white, always warm
- **Dark text**: `#0F1C1A` on light surfaces
- **Teal light**: `#E8F5F3` — card fills, soft container backgrounds
- **Typography (Latin)**: Inter — same as website, all weights available
- **Typography (Arabic)**: Scheherazade New or Amiri — large, elegant, serif.
  Used exclusively for Quranic text, duas, and dhikr.
- **Border radius**: 14px default, 20px for cards, 28px for modals
- **Shadows**: Teal-tinted, never grey (`rgba(13,124,110,0.10)`)

## Component Inventory

| Component | Status | Notes |
|---|---|---|
| Bottom navigation bar | New | 4 tabs: Home, Tasks, Progress, Therapists |
| "I'm Struggling" panic button | New | Large, full-width, home screen. Primary CTA. |
| Intervention sequence modal | New | Full-screen overlay. Dua → Breathing → Task → Call |
| Arabic text display block | New | 3-layer: Arabic (large serif) / Transliteration / Translation |
| Dhikr counter | New | Large tap target, bead-style counter, vibration feedback |
| Streak display | New | Days clean counter, prominent on home screen |
| Daily task card | New | Checkbox-style, shows task name + estimated time |
| Milestone badge | New | Unlockable, named with Islamic virtues (Sabr, Tawbah, etc.) |
| Therapist profile card | New | Photo, name, specialty (counsellor/scholar), availability dot |
| Call screen | New | Full-screen audio call UI, mute/end controls |
| Onboarding flow (3 screens) | New | Addiction type → Journey stage → Therapist preference |
| Progress chart | New | Weekly/monthly streak and task completion view |
| Prayer time banner | New | Subtle reminder strip, not a full prayer app |
| Breathing exercise overlay | New | Animated expand/contract circle, timed |

## Key Interactions

**Crisis intervention (the most important flow):**
1. User taps "I'm Struggling" — full-screen overlay opens immediately, no
   loading, no confirmation dialog.
2. Screen 1: Short dua displayed (Arabic + transliteration + translation).
   Auto-plays audio. User reads along. "Continue" appears after 10 seconds.
3. Screen 2: Breathing exercise. Animated circle expands (inhale 4s) holds
   (4s) contracts (exhale 4s). 3 cycles. Skip available.
4. Screen 3: Physical task assigned (one from the pool, randomised). Large
   checkbox. "I did it" button.
5. Screen 4: Gentle affirmation + option to call a therapist or return home.
   Never forced. "You're doing well. That took strength."

**Daily rhythm loop:**
- Morning: Fajr time notification → open app → set daily intention → see
  today's dhikr quota.
- Throughout day: Task reminders (not aggressive — max 2 per day). Streak
  counter visible on home screen at all times.
- Evening: Gentle reflection prompt → gratitude line → streak updated.

**Therapist call:**
- User opens Therapists tab → sees available counsellors and scholars with
  live availability indicators → taps profile → taps "Call Now" →
  audio call connects via Agora RTC.

**Streak and reward:**
- Completing daily tasks adds to streak counter.
- Milestone days (7, 30, 90, 180, 365) unlock named badges with a short
  congratulatory screen showing the badge and an ayah related to patience
  or tawbah.
- Relapse resets the streak counter but shows a specific "Return" screen —
  never just a cold reset. Reminds the user that tawbah is always open.

## Responsive Behavior

This is a mobile-only app (iOS and Flutter/Android). All layouts are designed
for portrait mode on standard phone sizes (375px–430px wide). No tablet
layout required in this phase.

Key behaviors:
- The "I'm Struggling" button must always be visible on the home screen
  without scrolling, regardless of screen height.
- Arabic text blocks scale with system font size (accessibility).
- Bottom navigation stays fixed at all times.

## Accessibility Requirements

- All interactive elements minimum 44×44pt tap targets.
- Arabic text minimum 24sp — never smaller. Adjust transliteration to 14sp.
- Colour contrast: all body text against backgrounds meets WCAG AA (4.5:1).
- Teal `#0D7C6E` on white `#FFFFFF` = 4.7:1 — passes AA.
- Gold `#C9933A` is accent only — never used for body text.
- Screen reader labels on all icon-only buttons (especially call controls).
- Breathing exercise animation respects `prefers-reduced-motion`.
- Dhikr counter has haptic feedback (vibration) as the primary feedback
  channel — not just visual.

## Task Pool (Physical & Verbal Tasks)

The app selects from this pool during crisis intervention and daily scheduling:

**Verbal / Remembrance:**
- SubhanAllah × 33, Alhamdulillah × 33, Allahu Akbar × 34 (one full round)
- Istighfar × 100 (Astaghfirullah)
- Salawat × 100 (Allahumma salli ala Muhammad)
- Recite Surah Al-Ikhlas × 3
- Recite Ayat Al-Kursi

**Physical:**
- Make wudu
- Pray 2 raka'at nafl
- Read 1 page of Quran
- Drink a full glass of water
- Go for a 5-minute walk (timer in app)
- Splash cold water on face

Tasks can be customised by the user after onboarding is complete.
During crisis intervention, the app assigns one task — never a menu.

## Onboarding Flow (3 Screens)

**Screen 1 — What are you working through?**
- Options: Alcohol / Drugs / Prescription medication / Prefer not to say
- Skip available. No shame in skipping.

**Screen 2 — How long have you been on this journey?**
- Options: Just starting / A few weeks / A few months / Over a year

**Screen 3 — Would you like access to a therapist?**
- Options: Yes, connect me / Maybe later
- Brief note: "Licensed counsellors and Islamic scholars available on demand."

After screen 3 → straight to home screen. No email wall, no paywall, no
lengthy profile setup. Value first.

## Out of Scope

- Group sessions or community features (forums, chat rooms) — Phase 2
- Quran reader (full Quran in-app) — link out to an existing app instead
- Prayer tracker (full salah tracking) — separate concern, not this app
- Android in-app payments (Paystack WebView) — Phase 2; iOS payment flow first
- Video calling — audio-only in this phase
- Therapist scheduling / calendar booking — on-demand only in this phase
- Localization beyond English and Arabic text display
- Dark mode — single light theme in Phase 1
