# Phase 1: Close the Loops — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every number on screen comes from something the user visibly did, is stored on the device, and survives a restart.

**Architecture:** Raw facts (signal readings, XP events, counters, baseline answers) are persisted in SharedPreferences by one `WellnessRepository`. Pure engines derive everything else: `CogniPulseEngine` (score + breakdown + daily history), `ProgressEngine` (level, streak, badges), `InsightEngine` (pattern cards), `TypingAnalyzer` (typing check-in score). `AppStateNotifier` holds the raw facts and exposes the derived values; screens only read.

**Tech Stack:** Flutter, Riverpod (StateNotifier), shared_preferences, sqflite (game sessions, already present), fl_chart.

**Spec:** Phase 1 in the review-prep plan (memory `review-prep-phases`) and ZENO_PRD.docx §5.2 (signal weights), §5.3 (quests), §5.4 (insights), §6.1 (onboarding with a 5-question baseline).

## Global Constraints

- PRD signal weights: phone usage 30%, typing 35%, face scan 20%, self-reported mood 15%.
- Phone usage is **not measured** in this build. It is shown as "not measured" and its weight is left out, never faked.
- Game play is an extra signal (not in the PRD) at 15%; the baseline questionnaire is an always-present prior at 10%.
- Today's score = weighted mean of the **latest reading of each signal type logged today** plus the baseline, divided by the sum of weights actually used.
- No mock week, no mock XP/level/streak/badges on a fresh install. Defaults: level 1, 0 XP, streak 0, all badges locked.
- Level = `totalXp ~/ 250 + 1`; XP to next level is always 250.
- XP: quests give their `xpReward`; a finished game gives its `xpReward`; mood log, typing check-in and face scan give 5/15/15 XP the first time each day.
- No `setState` for cross-widget state; theme text styles only; `HapticFeedback.lightImpact()` on meaningful taps.

## Review Focus

1. Fresh install with onboarding skipped (no baseline answers) → score is a labelled neutral 60, Insights shows empty states, nothing crashes.
2. Day rollover → quests reset, today's XP resets, the score falls back to the baseline until a new check-in; history keeps yesterday.
3. Corrupt or old-format SharedPreferences JSON → the app starts with empty data instead of crashing.
4. Typing check-in where the user pastes, types nothing, or types far more than the sentence → the score stays within 0–100 and the button stays disabled until there is input.
5. Streak with a gap → resets; a streak whose last activity was yesterday still counts until today ends.

---

### Task 1: Signal + XP models, repository, CogniPulse engine

**Files:** Create `lib/models/signal_reading.dart`, `lib/models/baseline.dart`, `lib/models/xp_event.dart`, `lib/services/wellness_repository.dart`, `lib/services/cognipulse_engine.dart`. Test `test/services/cognipulse_engine_test.dart`, `test/services/wellness_repository_test.dart`.

**Interfaces (produces):**
- `enum SignalType { selfReport, typing, faceScan, game }`; `class SignalReading { SignalType type; int score; DateTime at; double? stress; double? mood; String? note; toMap/fromMap }`
- `class BaselineResult { List<int> answers; DateTime at; int get score; double get stress; double get mood }` (answers 1–5, oriented so 5 = good).
- `class XpEvent { String source; String? sourceId; int amount; DateTime at }`
- `class CogniPulseEngine { static const weights; static CogniPulseBreakdown today(List<SignalReading>, BaselineResult?, DateTime now); static List<DaySummary> lastDays(List<SignalReading>, BaselineResult?, DateTime now, {int days = 7}) }`
- `CogniPulseBreakdown { int score; List<SignalContribution> parts; bool hasCheckInToday }`, `SignalContribution { String label; int? value; double weight; double share; DateTime? at; bool measured }`
- `DaySummary { DateTime day; int? score; double? stress; double? mood; int readings }`

Tests: weighted mean renormalises over measured signals; latest reading per type wins; yesterday's readings ignored today; no baseline → neutral 60; phone usage always unmeasured; corrupt JSON loads as empty.

### Task 2: Progress engine (XP, level, streak, badges) + AppState rewrite

**Files:** Create `lib/services/progress_engine.dart`; rewrite `lib/providers/app_state_provider.dart`, `lib/models/user_profile.dart`; trim `lib/mock_data.dart` (remove mock user/week; keep quest catalog and dialogue). Test `test/services/progress_engine_test.dart`, `test/providers/app_state_test.dart`.

**Interfaces:** `ProgressEngine.level(int totalXp)`, `xpIntoLevel`, `currentStreak(Set<DateTime> activeDays, DateTime now)`, `longestStreak`, `badges(BadgeStats)`. Notifier methods: `logMood(int value)`, `recordTypingCheckIn(TypingResult)`, `recordFaceScan(FaceScanEntry)`, `recordGameSession({gameId, xp, signalScore})`, `completeQuest(id)`, `recordBreathingSession()`, `cycleDialogue()` (also counts Mochi taps), `saveBaseline(BaselineResult)`, `updateUserName`.

Tests: completing a quest adds XP once and persists across a new notifier; quests reset next day; streak counts consecutive days; badges unlock from real stats.

### Task 3: Self-report mood on Home + "Why is my score X?" sheet

**Files:** Modify `lib/widgets/quick_mood_log.dart` (Riverpod, 5 values 10/30/50/70/90, shows today's pick), `lib/screens/home/home_screen.dart` (add mood log, tap CogniPulse card → sheet, Daily Quest button → Quests tab), create `lib/widgets/score_breakdown_sheet.dart`. Test `test/widgets/score_breakdown_sheet_test.dart`.

### Task 4: Typing check-in in Scan

**Files:** Create `lib/services/typing_analyzer.dart`, `lib/widgets/typing_check_in.dart`; modify `lib/screens/scan/scan_screen.dart` (segmented Face / Typing). Test `test/services/typing_analyzer_test.dart`.

Score = `100 × (0.35·accuracy + 0.25·speed + 0.25·(1 − corrections) + 0.15·(1 − pauses))`; speed = min(1, wpm/40); corrections = min(1, backspaces/typedChars × 4); pauses = share of gaps > 1.5 s.

### Task 5: Games feed the engine and award XP

**Files:** Modify `lib/services/game_feature_pipeline.dart` (`computeSignalScore` = 60 + adjustment×2, clamped), `lib/screens/games/game_wrapper.dart`, `lib/screens/games/playroom_screen.dart` (recommendation from today's summary). Test: extend `test/services/game_feature_pipeline_test.dart`.

### Task 6: Box Breathing quest via QuickBreathingCard

**Files:** Modify `lib/widgets/quick_breathing_card.dart` (fixed rounds, `onComplete`, cancel-safe loop), `lib/screens/quests/quests_screen.dart` (breathing quest opens a sheet with the card). Test `test/widgets/quick_breathing_card_test.dart`.

### Task 7: Baseline questionnaire in onboarding

**Files:** Create `lib/screens/onboarding/baseline_page.dart`; modify `lib/screens/onboarding/onboarding_flow.dart` (Welcome, Name, Companion, Baseline, Permissions, Meet Mochi); correct the Permissions copy (phone usage not measured, typing = in-app check-in). Test: extend `test/app_smoke_test.dart`.

### Task 8: Insights from real data

**Files:** Create `lib/services/insight_engine.dart`; rewrite `lib/screens/insights/insights_screen.dart` (real weekday labels, score/stress/mood lines with gaps, stat cards, rule-based `InsightCorrelationCard`s, game history from sqflite, check-in history); provider `recentGameSessionsProvider`. Test `test/services/insight_engine_test.dart`.

### Task 9: Profile from real data

**Files:** Modify `lib/screens/profile/profile_screen.dart` (level/XP/streak/quests/avg from state, badges with progress, weekly letter generated from the week's stats), `lib/widgets/cognipulse_ring.dart` (drop MockData delta).

### Task 10: Verify

`flutter analyze` (no new issues vs. 49 baseline), `flutter test`, `flutter build apk --debug`.
