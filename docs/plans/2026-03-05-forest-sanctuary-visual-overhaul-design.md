# ZENO Forest Sanctuary Visual Overhaul — Design Doc
**Date:** 2026-03-05
**Status:** Approved
**Scope:** Colour palette, Mochi cinematic intro, onboarding animations, quest stagger, CogniPulse transitions, hero animations

---

## Goals

1. Evoke calm, comfort, and groundedness — "forest sanctuary" aesthetic
2. Make Mochi's first appearance genuinely memorable and interactive
3. Add motion that feels intentional and alive, not decorative noise
4. Maintain Flutter performance (60fps, no janky rebuilds)

---

## 1. Colour Palette (app_theme.dart)

| Token | Old | New |
|---|---|---|
| `backgroundDeep` | `#E8E5F0` | `#F2F5EF` |
| `backgroundMid` | `#EFECF7` | `#EFF3EC` |
| `cardSurface` | `#FFFFFF` | `#FAFCF8` |
| `cardSurfaceLight` | `#F5F3FA` | `#F4F7F2` |
| `primaryAccent` | `#A78BFA` | `#7AB87A` |
| `warmAccent` | `#F9A875` | `#D4A574` |
| `textPrimary` | `#1A1A2E` | `#2A3828` |
| `textSecondary` | `#8A8899` | `#7A8C80` |
| `successMint` | `#34C77B` | `#5BBF8A` |
| `selectedTint` | `#EEF9F1` | `#EDF5ED` |
| `selectedBorder` | `#34C77B` | `#5BBF8A` |
| `buttonDark` | `#1A1A2E` | `#2A3828` |
| `warningAmber` | `#FCD34D` | `#E8A84A` |

### Mochi Mood Colours
| Mood | Old | New |
|---|---|---|
| Thriving | `#F9A875` | `#D4A574` (warm wood amber) |
| Balanced | `#A78BFA` | `#7AB87A` (sage green) |
| Drifting | `#7B8FA6` | `#8BA89B` (grey-green mist) |
| Struggling | `#6E7A8A` | `#7A8B84` (desaturated green) |

### Ambient Gradients (CogniPulse → background)
```
score >= 80 (Thriving):  [#E8F0E8, #EFF3EC, #EAF2EA]  — bright moss
score >= 55 (Balanced):  [#EFF3EC, #F2F5EF, #EFF3EC]  — soft forest
score >= 30 (Drifting):  [#EDF0EC, #F2F5EF, #EDF0EE]  — muted woodland
score <  30 (Struggling):[#F5EFE8, #F2F5EF, #F0EDE8]  — warm clay dusk
```

---

## 2. Mochi Cinematic Introduction (MeetMochi Page)

### Animation Timeline

| Phase | Timing | What happens |
|---|---|---|
| Forest canvas | 0–400ms | Deep forest-green bg fades in behind soft gradient |
| Seed drop | 400–900ms | Tiny acorn icon falls from top with spring bounce on land |
| Sprout | 900–1600ms | Acorn scales up elastically, morphs into small Mochi silhouette |
| Mochi grows | 1600–2400ms | Full MochiWidget expands with overshoot bounce; glow ring pulses outward |
| Leaf burst | 2200–2600ms | 8 leaf particles orbit Mochi then drift away with physics |
| Fireflies | 2400ms+ (Thriving only) | Golden dots wander with sine-wave paths |
| Greeting text | 2400ms+ | Name-personalised greeting slides up with fade |
| Typewriter | 2600ms+ | Dialogue renders character-by-character |
| CTA button | 3000ms+ | "Let's thrive" pill fades in |

### Interactivity
- Tap Mochi at any point → happy bounce + 6 leaf particles burst from tap point
- Decorations are scattered forest emojis: 🌿 🍃 ✨ 🌱 🌸 with slow float animations

### MochiPainter additions (intro-only flag)
- Leaf crown: two small bezier leaves atop the head, painted when `showCrown: true`
- Enhanced Thriving glow: layered concentric MaskFilter blurs (3 radii)

---

## 3. Onboarding Animations

### Page transitions
Replace default `NeverScrollableScrollPhysics` PageView with custom `PageController` + manual `AnimatedSwitcher` or `CustomTransitionPage` per page giving a parallax horizontal slide: foreground content slides at 1x, background colour at 0.3x speed.

### Per-page animations
| Page | Animation |
|---|---|
| Welcome | Mochi descends from above with leaf trail; floating chips drift in with 80ms stagger |
| Name Entry | Mochi on right pulses gently; typed name scales up with spring |
| Avatar Select | Each row slides in from right with 60ms stagger on page enter |
| Permissions | Each permission card slides in from left with 80ms stagger |
| Meet Mochi | Full cinematic sequence |

### Progress indicator
Dot-style progress bar at top (5 dots) with animated active dot that scales + fills.

---

## 4. Quest Cards — Staggered Entrance (QuestsScreen + QuestCard)

- `QuestsScreen` passes `index` to each `QuestCard`
- Each card: `delay = index * 60ms`, animation: `fadeIn + slideY(begin: 0.25, end: 0)`, duration 400ms, curve easeOutCubic
- Entrance fires once per screen mount (no re-animation on state changes)
- Completion burst: green checkmark draws itself via animated path, small "+XP" text floats up and fades over 600ms using `flutter_animate`

---

## 5. CogniPulse Ring Transitions

- **Score counter**: `TweenAnimationBuilder<int>` counting from previous to new value, duration 1000ms, spring-like easing
- **Ring arc colour**: `ColorTween` between current and target mood colour on score change, duration 800ms
- **Ring glow**: subtle shadow ring at mood colour, alpha 0.15, `AnimatedContainer` on colour
- **Mood label**: `AnimatedSwitcher` with `FadeTransition + ScaleTransition` (scale 0.85→1.0) on mood change
- **Pulse on change**: `AnimationController` fires a single pulse (scale 1.0→1.06→1.0) when score updates

---

## 6. Hero Animations

- `MochiWidget` on Home screen wrapped in `Hero(tag: 'mochi-hero')`
- Scan screen's Mochi (if any) uses same tag for cross-screen flight
- Bottom nav bar: animated forest-green indicator bar slides between tabs (replace default dot with a custom `AnimatedPositioned` bar)

---

## 7. Other Screen Entrance Animations

All main screens (Home, Quests, Insights, Scan, Profile) get a lightweight entrance:
- `flutter_animate` `.fadeIn(duration: 300ms).slideY(begin: 0.06, end: 0)`
- Applied to the root `SingleChildScrollView` or `Column` content

---

## Files to Modify

| File | Changes |
|---|---|
| `lib/theme/app_theme.dart` | Full palette update + new ambient gradients |
| `lib/widgets/mochi_widget.dart` | Add `showCrown` flag, enhanced Thriving glow, leaf crown painter |
| `lib/screens/onboarding/onboarding_pages.dart` | Per-page stagger anims, parallax transition, progress dots |
| `lib/screens/onboarding/onboarding_flow.dart` | Progress indicator, parallax page transition |
| `lib/screens/home/home_screen.dart` | Hero tag on Mochi, entrance animation |
| `lib/screens/quests/quests_screen.dart` | Pass index to QuestCard |
| `lib/widgets/quest_card.dart` | Staggered entrance + completion burst |
| `lib/widgets/cognipulse_ring.dart` | ColorTween, score counter, pulse, mood AnimatedSwitcher |
| `lib/widgets/ambient_background.dart` | Updated gradient colours |
| `lib/router/app_router.dart` | Enhanced bottom nav indicator |
| `lib/router/scaffold_with_nav.dart` | Animated nav indicator |

## New Files

| File | Purpose |
|---|---|
| `lib/widgets/leaf_particle.dart` | Reusable floating leaf particle widget |
| `lib/widgets/mochi_intro_sequence.dart` | Extracted cinematic intro controller |

---

## Constraints

- No new packages beyond already-installed `flutter_animate`
- All animations use `AnimationController` + `flutter_animate` — no third-party physics engines
- `RepaintBoundary` wraps heavy particle widgets
- `Mochi must always be animating` — existing breathing loop preserved
