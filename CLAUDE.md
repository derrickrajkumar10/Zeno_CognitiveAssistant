# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ZENO is a gamified AI cognitive wellness Flutter app for Gen Z. The emotional core is **Mochi** — a Tamagotchi-style bear-cub companion whose mood, expressions, and dialogue respond to the user's passively-detected stress level (the **CogniPulse Score**, 0–100). This is a hackathon/ideathon demo: no backend, all data mocked, runs with `flutter run`.

## Commands

```bash
# Run the app (debug)
flutter run

# Run on a specific device
flutter run -d <device_id>

# Build for release
flutter build apk --release          # Android
flutter build ios --release          # iOS

# Analyze and lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widgets/mochi_widget_test.dart

# Get dependencies
flutter pub get

# Check outdated packages
flutter pub outdated
```

## Architecture

### State Management
All app state lives in Riverpod providers (`lib/providers/`). The central provider is `AppStateNotifier`, which holds: current user, CogniPulse score, active Mochi mood state, quest completion states, and onboarding status. **Never use `setState` for cross-widget state** — use Riverpod.

### Navigation
`go_router` with a persistent bottom nav bar (5 tabs: Home / Quests / Insights / Scan / Profile). Onboarding is a separate `/onboarding` route gated by `shared_preferences` (`onboarding_complete` key). After onboarding, all navigation goes through the shell route with the bottom nav.

### Mochi Character
`lib/widgets/mochi_widget.dart` is the most important widget in the app. Mochi is drawn entirely with `CustomPainter` — round head, Bezier-curve ears, dot eyes, belly — all parameterized by `MochiMoodState`. An `AnimationController` drives a continuous breathing/bobbing idle loop. `flutter_animate` handles tap reactions and entrance animations. A separate `ParticleOverlay` widget emits floating sparkles only in the `Thriving` mood state. **Mochi must always be animating** — never a static render.

### CogniPulse → Mochi Mood Mapping
```
80–100 → Thriving   (golden glow, sparkles, bouncy)
55–79  → Balanced   (soft lavender, slow breathe, gentle smile)
30–54  → Drifting   (muted blue-grey, slow blink, slouch)
0–29   → Struggling (desaturated, droopy eyes, very slow)
```
This mapping lives in `lib/models/mochi_state.dart` and is used everywhere.

### Ambient Background
`lib/widgets/ambient_background.dart` wraps every scaffold. It reads the CogniPulse score from Riverpod and animates a gradient transition: cool indigo (high score) → warm amber (low score). Every screen sits on top of this — **do not use solid background colors on screens**.

### Mock Data
`lib/mock_data.dart` is the single source of truth for all demo data: user profile ("Alex", Level 4, 1240 XP, 5-day streak), 7-day CogniPulse readings, 80+ Mochi dialogue lines (20+ per mood state), 3 weekly letters, quest history, badge states. **No screen fetches from a real API** — all screens consume mock data or Riverpod providers seeded from it.

### Ollama / AI Integration
`lib/services/ollama_service.dart` fires a POST to `http://localhost:11434/api/generate` (llama3.2 model) with Mochi's system prompt injected with the current score and mood state. Hard timeout: 3 seconds. **Any error or timeout → silent fallback to mock dialogue array from `mock_data.dart`.** The user never sees an error. A small debug FAB (bottom corner, Home screen only) shows `[LIVE]` or `[MOCK]` status — for demo use only.

### Theme
`lib/theme/app_theme.dart` defines the full design system. Key values:
- Background: `#0D1B2A`, Card surface: `#1A2940`, Primary: `#A78BFA`, Accent: `#F9A875`
- Font: Nunito (Google Fonts) everywhere — `Theme.of(context).textTheme` only, never raw `TextStyle` with hardcoded fonts
- Border radius: 20–32px on all cards and containers
- **No pure black, no pure white, no sharp edges anywhere**

## Key Constraints

- **Frontend only** — no backend, no server files, no real API calls except Ollama localhost
- **Flutter (Dart)** is the confirmed stack — the `ZENO_Pitch.docx` incorrectly says React Native; ignore that
- Haptic feedback (`HapticFeedback.lightImpact()`) on every meaningful tap: Mochi, quest complete, scan trigger
- All screen transitions use a subtle fade — configure in go_router's `pageBuilder`
- The keyboard extension / typing behavior analysis is mocked in the Scan screen — no real keyboard layer
