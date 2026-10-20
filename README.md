# ZENO

[![CI](https://github.com/derrickrajkumar10/Zeno_CognitiveAssistant/actions/workflows/ci.yml/badge.svg)](https://github.com/derrickrajkumar10/Zeno_CognitiveAssistant/actions/workflows/ci.yml)

ZENO is a Flutter app that turns a few quick check-ins into a 0 to 100 wellness score called CogniPulse, and shows that score through Mochi, a small bear-cub companion who looks and talks differently depending on how your day is going. It was built for a hackathon and is now being prepared for a software engineering review, so everything runs on the phone: there's no backend, and nothing you enter leaves the device.

ZENO is a wellness toy. It isn't a medical tool and doesn't diagnose anything.

## What it actually measures

Every number on screen comes from something you did in the app. Nothing is pre-filled. A fresh install starts at a neutral score with no history.

| Signal | How it's measured | Weight in CogniPulse |
|---|---|---|
| Typing check-in | You type a practice sentence on the Scan tab. Speed, accuracy (edit distance), backspaces and pauses over 1.5 s become a 0 to 100 score. Nothing typed anywhere else is read. | 0.35 |
| Face check-in | A 5-second front-camera scan. Google ML Kit face detection (on-device) gives smile and eye-open probabilities plus head angles, and a hand-written formula in `face_scan_analyzer.dart` turns those into mood, focus and stress. | 0.20 |
| Mood check-in | You tap one of five moods on Home. | 0.15 |
| Games | Eight mini-games in the Playroom. Reaction time, misses and hesitation are compared with your own last 7 days of play. | 0.15 |
| Baseline questionnaire | Five questions during onboarding, used as a light prior every day. | 0.10 |
| Phone usage | **Not measured.** The PRD gives it 0.30, but this build has no usage tracking, and the score breakdown says so. | (0.30, unused) |

The score for today is the weighted mean of the latest reading of each signal you've given today, plus the baseline, with weights rescaled over whatever was actually measured. Tap the score on Home to see the breakdown.

ML Kit is the only machine-learning component that runs. The TFLite model under `ml/` is a training experiment and the app doesn't load it.

## Features

- **Home**: Mochi, today's CogniPulse with a "why is my score X?" breakdown, a mood check-in, a game suggestion and the daily quest.
- **Quests**: seven daily quests with XP. Box Breathing runs a real 4-4-4-4 breathing session and only completes when you finish it.
- **Playroom**: eight games (Bubble Drift, Mochi Says, Wave Sync, Memory Garden, Slice & Calm, Focus Flicker, Dream Sort, Mochi's Puzzle World). Finishing one gives XP and a game signal; quitting early gives neither.
- **Scan**: the face check-in and the typing check-in.
- **Insights**: a 7-day CogniPulse, stress and mood chart with real weekday labels, rule-based patterns (trend, best day, morning vs evening, typing vs mood), and your check-in and game history.
- **Profile**: level, XP, streak, badges with progress, Mochi's weekly letter written from your week, edit name, reset all data, and an About sheet that lists what is and isn't measured.
- **Mochi's dialogue**: from a local Ollama model (llama3.2) if one answers within 3 seconds, otherwise from built-in lines. The user never sees an error.

XP, level (250 XP per level), streak and badges are all derived from stored events, so they change only when you do something.

## Running it

You need Flutter 3.47.7 (stable) and an Android phone or emulator. Android is the only platform that has been tested.

```bash
flutter pub get
flutter run                 # debug build on the connected device
flutter build apk --release # release APK
```

### Optional: live Mochi dialogue with Ollama

```bash
ollama pull llama3.2
OLLAMA_HOST=0.0.0.0 ollama serve   # 0.0.0.0 so a phone on your Wi-Fi can reach it
```

The Android emulator reaches your computer at `10.0.2.2:11434`, which is the default. On a real phone, open the developer panel and set the host to your computer's LAN IP, for example `192.168.1.5:11434`.

### Developer panel (for demos)

Long-press Mochi on the Profile tab. From there you can:

- override the score with a slider. The override is labelled "Demo override" on Home and is never saved.
- seed a demo week. Every seeded row is tagged so it can be found and removed.
- set the Ollama host and see whether Mochi is LIVE or MOCK.
- view the raw stored data as JSON.

## Quality checks

```bash
flutter analyze --fatal-infos               # 0 issues
flutter test --coverage                     # 156 tests
dart run tool/coverage_summary.dart --files # 80.8% line coverage
```

GitHub Actions runs the same three steps on every push and pull request, fails below 75% coverage, and builds a debug APK (`.github/workflows/ci.yml`).

## Docs

- [Architecture](docs/ARCHITECTURE.md): layers, data flow, the scoring formulas, storage and testing
- [PRD traceability](docs/PRD_TRACEABILITY.md): every PRD requirement, its status, the code and the test that proves it
- [Plans](docs/plans/): the implementation plan for each review-prep phase

## Project layout

```
lib/
  main.dart              app entry, ProviderScope, router
  models/                plain data classes (signals, XP events, scans, game sessions)
  providers/             Riverpod state: AppStateNotifier and Mochi's personality
  services/              scoring engines, analyzers, repositories, Ollama client
  screens/               one folder per tab, plus onboarding, splash, games, developer panel
  widgets/               Mochi, cards, sheets and check-in widgets
  theme/app_theme.dart   colours, type scale, spacing
test/                    unit and widget tests, mirroring lib/
tool/coverage_summary.dart
ml/                      offline training experiment, not used by the app
```
