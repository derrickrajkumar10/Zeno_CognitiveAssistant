# Phase 3: SE Evidence — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the reviewer hard evidence of engineering quality: a clean analyzer, tests with measured coverage, CI that runs both on every push, no dead code, and docs that describe the app as it really is.

**Architecture:** No product behaviour changes. Dead widgets go; analyzer infos are fixed at the source rather than silenced; new unit tests cover the face-scan formula and the game signal pipeline, the two parts that turn raw input into a score and had 0–17% coverage. A small Dart script summarises `coverage/lcov.info` so CI and the README quote the same number.

**Tech Stack:** Flutter 3.47.7 stable, flutter_test, GitHub Actions (`subosito/flutter-action@v2`, `actions/setup-java@v4`), Markdown + Mermaid.

**Spec:** Phase 3 in the review-prep plan (memory `review-prep-phases`): 30+ tests and coverage; `flutter analyze` at 0 issues; remove or integrate the unused widgets; GitHub Actions CI; README and architecture doc; PRD traceability matrix (avatar names differ from the PRD).

## Global Constraints

- Honesty rule: docs never claim phone-usage tracking, a keyboard layer, MediaPipe or the TFLite model runs. Face scan = ML Kit probabilities + the hand-written formula in `face_scan_analyzer.dart`.
- No `// ignore:` comments and no lint rules switched off to reach 0 issues.
- `withOpacity(x)` becomes `withValues(alpha: x)` (same colour; the replacement the deprecation names).
- Baseline before the phase: 114 tests, 57.1% line coverage, 43 analyzer issues, 6 widget files unreachable from `lib/main.dart`.
- One commit per task.

## Review Focus

1. A face scan where no frame had a face (`samples` empty, `framesProcessed > 0`) → finite scores in 0–100 and the "only caught part of you" insight, never NaN.
2. A game ended before any tap → error rate 0, hesitation 0, no division by zero.
3. Removing `lottie` and `assets/animations/` → nothing else references them; the debug APK still builds.
4. CI's Flutter version drifting from the local one → pin `flutter-version: 3.47.7`.
5. Coverage script given an lcov file with zero lines → prints 0.0%, does not divide by zero.

---

### Task 1: Remove dead widgets

**Files:** Delete `lib/widgets/{cognipulse_calendar,cognipulse_ring,create_quest_sheet,leaf_particle,mochi_accessories_grid,mochi_lottie_widget}.dart`, `assets/animations/`. Modify `pubspec.yaml` (drop `lottie`, drop the `assets/animations/` entry), `pubspec.lock` via `flutter pub get`.

- Decision: remove all six. The calendar and accessories grid render seeded `Random(42)`/hard-coded mock data (exactly what the honesty rule bans); the ring duplicates Home's score display; the quest sheet and Lottie bear were never wired; Mochi is the CustomPainter.
- [ ] Delete, `flutter pub get`, `flutter analyze` (issue count drops, no errors), `flutter test` (114 pass), commit.

### Task 2: Analyzer at zero

**Files:** Every file the analyzer lists (`withOpacity` sites, `prefer_const_*` sites in `app_theme.dart`, `glass_nav_bar.dart`, `quest_card.dart`), `lib/widgets/mochi_widget.dart` (remove unused `_lookAnim`, `_isBlinking`, `_tapCount` and anything only they used).

- [ ] Replace `.withOpacity(` → `.withValues(alpha: `; add the consts; delete unused fields.
- [ ] `flutter analyze --fatal-infos` → "No issues found!"; `flutter test` green; commit.

### Task 3: Test the face-scan formula

**Files:** Create `test/services/face_scan_analyzer_test.dart`, `test/models/face_scan_entry_test.dart`.

- Interface: `FaceScanAnalyzer().buildEntry({required List<FaceFrameSignal> samples, required int framesProcessed, DateTime? scannedAt}) → FaceScanEntry`.
- Tests:
  - smiling, eyes open, still, centred, full coverage → `score >= 85`, `stressIndex <= 15`, insight mentions "steadiness".
  - frowning (smile 0), eyes half closed, head turned 35°/rolled 25° → `stressIndex >= 65`, score lower than the calm case, "wound up" insight.
  - empty samples with `framesProcessed: 30` → all fields finite and within 0–100, coverage 0, "only caught part" insight.
  - `framesProcessed: 0` → coverage 0, no exception.
  - head-angle sign does not matter: yaw −20 and +20 give the same score.
  - `FaceScanEntry.toMap`/`fromMap` round-trip; `toSignal()` carries type `faceScan`, score, stress, mood; `eyeOpenAverage` and `faceCoverage` getters.
- [ ] Write, run, commit.

### Task 4: Test the game signal pipeline

**Files:** Create `test/services/game_signal_collector_test.dart`, `test/services/game_repository_test.dart`, `test/models/game_session_test.dart`, `test/screens/game_wrapper_test.dart`; extend `test/services/game_feature_pipeline_test.dart`.

- Repository in tests: sqflite has no plugin under `flutter test`, so `GameRepository` falls back to SharedPreferences. `setUp`: `SharedPreferences.setMockInitialValues({})` then `await GameRepository().clearAll()`.
- Collector tests: 3 `tap_hit` + 1 `tap_miss` → `errorRate == 0.25`; events with `gameContext: {'exclude_from_accuracy': true}` are ignored; explicit `reactionTimeMs` values average correctly; flush with no taps → errorRate 0, hesitation 0, avgPressure 0.5; `takeLastFlushedEvents()` returns the events once (session_start + taps + session_end) then empty; pressure is clamped to 0–1.
- Model tests: `GameSession` and `GameBaseline` and `GameTouchEventRecord` `toMap`/`fromMap` round-trip (incl. `dropOffEarly` ↔ 0/1, `gameContext` JSON, missing delta keys → 0).
- Repository tests: saved sessions come back newest first from `getRecentSessions`; sessions older than `days` are excluded; `updateBaseline` averages recent sessions; `getTouchEventsForSessionIds` filters by id; `clearAll` empties everything.
- Pipeline test (real repo): no sessions → default vector (completion 1); 4 sessions with one `dropOffEarly` → `sessionCompletionRate == 0.75`; latest session much slower than the rest → `reactionMsZScore > 0`.
- Widget test: a `GameWrapper` whose builder shows a button that calls `endGame(score: 80, levelReached: 3)` → `PostGameScreen` shows `80%` and `+<xpReward>`; the close button before any end → results show `+0` XP. Pump with the app-state test harness used in `test/screens/*` (ProviderScope + prefs override), finish with `pumpWidget(SizedBox())` + `pump(30s)`.
- [ ] Write each file, run, commit.

### Task 5: Coverage summary script

**Files:** Create `tool/coverage_summary.dart`, `test/tool/coverage_summary_test.dart`.

- `CoverageSummary parseLcov(String lcov)` with `int linesFound`, `int linesHit`, `double percent` (0 when `linesFound == 0`), `List<FileCoverage> files`.
- `main(List<String> args)`: reads `coverage/lcov.info` (or `args[0]`), prints `Line coverage: 63.4% (3400/5360 lines, 70 files)`, and with `--min=N` exits 1 when below N. Excludes nothing; no hidden filtering.
- Tests: two-file sample → totals summed, percent correct; empty input → 0 files, 0.0%.
- [ ] Write, run `flutter test --coverage && dart run tool/coverage_summary.dart`, commit.

### Task 6: GitHub Actions CI

**Files:** Create `.github/workflows/ci.yml`.

- Trigger: push and pull_request on any branch.
- Job `analyze-and-test` (ubuntu-latest): checkout → flutter-action (`channel: stable`, `flutter-version: 3.47.7`, `cache: true`) → `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test --coverage` → `dart run tool/coverage_summary.dart --min=<floor>` where floor = measured coverage rounded down to the nearest 5 → upload `coverage/lcov.info` as an artifact.
- Job `build-apk` (needs the first): setup-java temurin 17 → flutter-action → `flutter build apk --debug` → upload the APK artifact.
- [ ] Validate YAML parses (`python3 -c 'import yaml…'` or `actionlint` if installed), commit. Running it needs a push, which is the user's call.

### Task 7: README and architecture doc

**Files:** Rewrite `README.md`; create `docs/ARCHITECTURE.md`.

- README: what ZENO is (one paragraph, honest), what is measured vs not, screenshots-free feature list, run/test/analyze/coverage commands, Ollama setup (emulator `10.0.2.2`, phone LAN IP + `OLLAMA_HOST=0.0.0.0`), developer panel (long-press Mochi on Profile), project layout, CI badge, "not a medical tool". Removes the false claims (Python ML backend, chatbot, cognitive assistant).
- ARCHITECTURE: layers (screens → widgets → providers → services → repositories → storage), Mermaid diagrams for the signal → score flow and navigation; CogniPulse fusion formula with weights (typing .35, face .20, self-report .15, game .15, baseline prior .10, phone usage .30 not measured), the face-scan formula, game pipeline, storage keys, Ollama fallback, testing strategy.
- [ ] Write, check every file path and number named in them exists in code, commit.

### Task 8: PRD traceability matrix

**Files:** Create `docs/PRD_TRACEABILITY.md`.

- One row per PRD requirement (§5.1–5.5, §6.1–6.3, §7 NFRs, §8 out of scope): requirement · status (Done / Partial / Not built / Out of scope) · where in code · which test proves it. Call out deviations: avatar archetypes (PRD: Mochi/Nyx/Flux/Pip/Lumi) vs what the app ships; phone usage and keyboard layer not built; MediaPipe → ML Kit; game signal added at 15%; quest list differs.
- [ ] Write, verify each referenced test name exists (`grep`), commit.

### Task 9: Verify the phase

- [ ] `flutter analyze --fatal-infos`, `flutter test --coverage`, `dart run tool/coverage_summary.dart`, `flutter build apk --debug`, all from a clean tree. Record the numbers in the README.
