# Imagery credits

All images are free for commercial use. Attribution is not required by either
licence; this file records provenance so assets can be re-sourced or replaced
without guesswork.

See `src/theme/backdrops.ts` for the treatment applied to each backdrop.

## Backdrops — `assets/bg/`

| File | Source | Used by |
|---|---|---|
| `canvas-night.jpg` | [Pexels 11872018](https://www.pexels.com/photo/11872018/) — lamplit mosque interior, light through geometric screens | **App canvas, dark mode** |
| `canvas-dawn.jpg` | [Pexels 27196949](https://www.pexels.com/photo/27196949/) — pale dawn sky with a crescent moon | **App canvas, light mode** |
| `arch-sanctuary.jpg` | [Pexels 20592568](https://www.pexels.com/photo/20592568/) — dark vaulted interior with stained glass | Welcome, auth, onboarding, milestone (dark) |
| `medallion-gold.jpg` | [Pexels 34982280](https://www.pexels.com/photo/34982280/) — gold calligraphic medallion on ink | Upgrade screen (dark in both themes) |
| `canvas-texture.jpg` | [Unsplash `photo-1534593963832-01c3595183bd`](https://unsplash.com/photos/1534593963832-01c3595183bd) — fine-grained stone surface | The `texture` backdrop variant (not the default — see below) |

`grain.png` is not a photograph. It is a 160×160 tileable noise texture
generated deterministically from a seeded PRNG, to break up the gradient
banding that large scrim fields produce on cheaper displays.

### Why `canvas-texture.jpg` is not the default

It is a flat, subjectless grey material. Composited at full screen it has no
contrast and no focal point, so at any opacity where it is visible at all it
reads as grey concrete and pulls the whole app off the lavender/ink palette;
at any opacity gentle enough to stay on-palette it is invisible. The `texture`
variant in `backdrops.ts` holds the most visible settings it supports — change
the `default` case in `backdrop()` to use it everywhere.

## Card artwork — `assets/cards/`

Each is dark and low-contrast by selection, because card labels sit directly on
top of them under a scrim rather than in a separate text area.

| File | Source | Used by |
|---|---|---|
| `quran.jpg` | [Pexels 36188877](https://www.pexels.com/photo/36188877/) — open Quran, teal illumination in warm light | Home → Explore → Quran |
| `duas.jpg` | [Pexels 16986213](https://www.pexels.com/photo/16986213/) — cupped hands raised in dua on black | Home → Explore → Duas |
| `dhikr.jpg` | [Pexels 36519373](https://www.pexels.com/photo/36519373/) — open Quran with prayer beads in sunlight | Home → featured daily dhikr |

## Replacing an image

Two treatments are in play, so match the one the slot expects:

- **The app canvas** stays visible the whole way down. Its scrim darkens hard
  behind the header, opens through the middle, and closes at the bottom — so
  the photo wants its interest in the **upper half** and nothing distracting
  behind the centre, where cards sit.
- **Card artwork** is scrimmed from the bottom up (`imageAnchor="bottom"`) or
  evenly (`"full"`). Pick images that are already dark; a bright photo will
  need the scrim pushed up and will lose most of its detail anyway.
