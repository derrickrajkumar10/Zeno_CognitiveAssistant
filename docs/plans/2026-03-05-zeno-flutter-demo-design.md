# ZENO Flutter Demo — Design Document
Date: 2026-03-05

## What We're Building
A complete, polished Flutter frontend demo for ZENO — a gamified AI cognitive wellness app for Gen Z. No backend. All data mocked. Runs with `flutter run`. Built for a hackathon/ideathon demo where judges need to *feel* something.

## Core Architecture Decisions

### Mochi Animation: CustomPainter + flutter_animate
Mochi is drawn programmatically via `CustomPainter`. Round head, Bezier-curve ears, dot eyes, belly — all parameterized by `MochiMoodState`. An `AnimationController` drives a continuous breathing/bobbing idle. `flutter_animate` handles tap reactions and entrance effects. A `ParticleOverlay` widget emits sparkles in Thriving state. This approach gives full control over every curve and expression, making Mochi feel genuinely alive.

### State: Riverpod
One central `AppStateNotifier` holds: user, cogniPulseScore, mochiMoodState, questStates, onboardingComplete. All screens `watch` the providers they need. No `setState` for shared state.

### Navigation: go_router Shell Route
A `ShellRoute` wraps all 5 main screens with a persistent bottom nav. Onboarding lives at `/onboarding`, gated by `shared_preferences`. After completion, redirects to `/home`.

### Ambient Background
`AmbientBackground` widget wraps every scaffold, animating a gradient from cool indigo (CogniPulse 100) to warm amber (CogniPulse 0). All screens are layered on top of this.

### Ollama Integration
`OllamaService` sends POST to `localhost:11434/api/generate` (llama3.2) with Mochi's system prompt + injected score + mood. 3-second timeout. Any failure → silent fallback to mock dialogue arrays. Debug FAB shows live/mock status.

## Package List
```yaml
flutter_riverpod: ^2.x
go_router: ^14.x
fl_chart: ^0.68.x
flutter_animate: ^4.x
google_fonts: ^6.x
http: ^1.x
shared_preferences: ^2.x
```

## File Structure
```
lib/
  main.dart                         # App entry, Riverpod scope, go_router config
  mock_data.dart                    # ALL mock data — single source of truth
  theme/
    app_theme.dart                  # Colors, typography, radius constants
  models/
    user_profile.dart
    cognipulse_reading.dart
    quest.dart
    mochi_state.dart                # MochiMoodState enum + CogniPulse mapping
  providers/
    app_state_provider.dart         # Central Riverpod notifier
  services/
    ollama_service.dart             # HTTP to localhost:11434, silent fallback
  screens/
    onboarding/
      onboarding_flow.dart          # PageView of 5 screens
      welcome_screen.dart
      name_entry_screen.dart
      avatar_selection_screen.dart
      permissions_screen.dart
      meet_mochi_screen.dart
    home/
      home_screen.dart
    quests/
      quests_screen.dart
    insights/
      insights_screen.dart
    scan/
      scan_screen.dart
    profile/
      profile_screen.dart
  widgets/
    mochi_widget.dart               # CustomPainter Mochi + animations
    cognipulse_ring.dart            # Animated circular progress ring
    quest_card.dart
    mochi_dialogue_bubble.dart
    ambient_background.dart
    mochi_notification_banner.dart  # Slide-in top banner
    particle_overlay.dart           # Thriving-state sparkles
```

## Mood → Visual Mapping
| State | Score | Body Color | Eyes | Animation |
|---|---|---|---|---|
| Thriving | 80–100 | Golden (#F9A875) | Wide, star pupils | Bouncy + sparkles |
| Balanced | 55–79 | Lavender (#A78BFA) | Normal, gentle smile | Slow breathe |
| Drifting | 30–54 | Muted blue-grey | Half-lidded | Slow blink, slouch |
| Struggling | 0–29 | Desaturated grey | Droopy | Very slow movement |

## Mock Data Summary
- User: Alex, Level 4, 1240 XP, 5-day streak
- 7-day scores: [58, 65, 71, 63, 78, 74, 73]
- 80+ Mochi dialogue lines (20+ per mood state)
- 3 weekly letters
- 5 quests with completion states

## Success Criteria
- Mochi feels alive (continuous animation, reactive expressions)
- Visual theme feels like a warm hug (dark navy, soft lavender, rounded)
- Quest completion triggers satisfying feedback (animation + XP + Mochi reaction)
- Ollama integration works when available; invisible when not
- `flutter run` with no configuration beyond Flutter SDK installed
