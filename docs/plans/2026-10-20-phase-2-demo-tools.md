# Phase 2: Demo Tools and Dead Ends — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every visible button does something real, and the presenter has a hidden panel to drive the demo without faking what the app measures.

**Architecture:** New behaviour lives on `AppStateNotifier` (reset, score override, demo seeding) and in two small services (`DemoSeeder`, Ollama host settings). A `DeveloperPanel` screen, opened by long-pressing the Profile avatar, calls them. Mochi reads its breathing period from `MochiMoodState`.

**Tech Stack:** Flutter, Riverpod (StateNotifier), shared_preferences, sqflite, http (+ `http/testing.dart` MockClient in tests).

**Spec:** Phase 2 in the review-prep plan (memory `review-prep-phases`): wire dead buttons (Daily Quest, Settings, edit name, reset data, About); hidden developer panel (score slider, seed/reset, Ollama host + LIVE/MOCK, JSON data viewer); mood-dependent Mochi breathing; Ollama via 10.0.2.2. Plus the three minors deferred from Phase 1.

## Global Constraints

- Honesty rule from the review plan: never claim a signal is measured when it is not. Settings that would need features this build lacks (notifications, themes) are removed, not faked.
- A score override is in memory only and is always labelled on Home ("Demo override"); a restart shows the real score.
- Seeded demo data is tagged `note: 'demo'` (signals) / `source: 'demo'`-free XP rows keep their normal sources but `sourceId` starts with `demo_`.
- Ollama: hard 3 s timeout, silent fallback to mock dialogue. Default host `http://10.0.2.2:11434` on Android, `http://localhost:11434` elsewhere; user-set host stored in prefs key `zeno.ollama_host`.
- `HapticFeedback.lightImpact()` on meaningful taps; theme text styles; no `setState` for cross-widget state.

## Review Focus

1. Reset while a game or sheet is open elsewhere in the tree → the app returns to onboarding with a fresh state and does not crash.
2. Ollama host typed without `http://` or with a trailing slash → normalised to `http://host:port` before use.
3. Edit name to an empty or whitespace string → rejected, name unchanged.
4. Seeding twice → no duplicate demo rows (seeding replaces earlier demo rows).
5. Score override set, then a real check-in → Home still shows the override (labelled) until it is cleared; the breakdown sheet says an override is active.

---

### Task 1: Close the Phase 1 leftovers and the Daily Quest button

**Files:** Modify `lib/screens/home/home_screen.dart` (Daily Quest → `context.go('/quests')`), `lib/screens/quests/quests_screen.dart` (complete the quest inside `onComplete`, not from the sheet's pop result), create `lib/widgets/day_rollover_watcher.dart`, modify `lib/router/scaffold_with_nav.dart` to wrap the shell in it. Tests: extend `test/screens/quests_screen_test.dart`, create `test/widgets/day_rollover_watcher_test.dart`, `test/screens/home_daily_quest_test.dart` (router-level).

- `DayRolloverWatcher({required Widget child, Duration checkEvery = const Duration(minutes: 1)})`: a `Timer.periodic` that calls `refreshClock()` only when the calendar date of `appClockProvider()` differs from `state.asOf`; timer cancelled in `dispose`.
- Tests: dismissing the sheet during the "Nice work" pause still completes the quest; watcher at 23:59 → clock moved to 00:01 → after one tick quests reset; Daily Quest tap lands on `QuestsScreen`.

### Task 2: Profile settings that work

**Files:** Modify `lib/screens/profile/profile_screen.dart`, `lib/providers/app_state_provider.dart`, `lib/services/game_repository.dart`; create `lib/widgets/edit_name_dialog.dart`, `lib/widgets/about_zeno_sheet.dart`. Test `test/screens/profile_settings_test.dart`, extend `test/providers/app_state_test.dart`.

- Settings become: **Edit name**, **Reset all data**, **About ZENO**. Notifications and Appearance are removed (no such features).
- `Future<String?> showEditNameDialog(BuildContext, {required String current})` returns the trimmed name or null; empty input keeps Save disabled. Tapping the name in the header opens it too.
- `AppStateNotifier.resetAllData()`: removes every `zeno.*` key and `onboarding_complete`, calls `GameRepository.instance.clearAll()` (new: deletes all three tables / prefs keys), and replaces state with a fresh `_load`. Profile then `context.go('/onboarding')`. Confirm dialog first ("Reset everything?").
- About sheet copy: what is measured (mood check-in, typing check-in, face scan via on-device ML Kit, games), what is not (phone usage), data stays on the phone, not a medical tool.
- Tests: reset clears XP/signals/baseline/name and sets `onboardingComplete` false; edit name with "  " cannot be saved; About lists "Phone usage" as not measured.

### Task 3: Mochi breathes with its mood

**Files:** Modify `lib/models/mochi_state.dart`, `lib/widgets/mochi_widget.dart`. Test `test/models/mochi_state_test.dart`.

- `Duration get breathPeriod` on `MochiMoodStateX`: thriving 1800 ms, balanced 2500 ms, drifting 3400 ms, struggling 4500 ms.
- Mochi sets `_breathCtrl.duration` from the mood on build and restarts `repeat(reverse: true)` when it changes (via `ref.listen` on `mochiMoodProvider`).
- Test: the four periods, strictly increasing as the mood worsens.

### Task 4: Ollama host setting

**Files:** Create `lib/services/ollama_settings.dart`; modify `lib/services/ollama_service.dart`. Test `test/services/ollama_settings_test.dart`, `test/services/ollama_service_test.dart`.

- `String normalizeOllamaHost(String input)`: trims, adds `http://` when no scheme, drops trailing `/`; empty → throws `FormatException`.
- `String defaultOllamaHost({required bool isAndroid})`.
- `ollamaHostProvider`: `StateNotifierProvider<OllamaHostNotifier, String>`; `OllamaHostNotifier.set(String)` normalises and persists to `zeno.ollama_host`; `reset()` returns to the default.
- `OllamaService({String baseUrl, http.Client? client, ...})`; `Future<bool> ping()` → GET `$baseUrl/api/tags`, true on 200 within 3 s. `ollamaServiceProvider` passes the host.
- Tests: normalisation cases; `ping` true on 200, false on 500 and on timeout/exception (MockClient); dialogue falls back to mock text when the client throws.

### Task 5: Score override and demo week

**Files:** Modify `lib/providers/app_state_provider.dart`, `lib/widgets/score_breakdown_sheet.dart`, `lib/screens/home/home_screen.dart`; create `lib/services/demo_seeder.dart`. Test `test/services/demo_seeder_test.dart`, extend `test/providers/app_state_test.dart`.

- `AppState.scoreOverride` (`int?`, not persisted); `cogniPulseScore => scoreOverride ?? breakdown.score`; `setScoreOverride(int? value)` (clamped 0–100, null clears).
- Home shows a "Demo override" chip near the ring while set; breakdown sheet shows "A demo override is active (real score: N)".
- `DemoSeeder.week(DateTime now, {int seed = 7})` → `({List<SignalReading> signals, List<XpEvent> xpEvents})`: the 6 days before today, each with a mood check-in, most with a typing check-in, some with a game; morning/evening times; deterministic from `seed`. Every signal `note: 'demo'` (game rows `note: 'demo:<gameId>'`), every XP row `sourceId` prefixed `demo_`.
- `seedDemoWeek()` removes earlier demo rows, then appends and persists.
- Tests: seeding twice gives the same counts; seeded week makes Insights' week have 6 days with data and today empty; override beats a real check-in until cleared.

### Task 6: Developer panel

**Files:** Create `lib/screens/developer/developer_panel.dart`; modify `lib/screens/profile/profile_screen.dart` (long-press the Mochi avatar → push panel on the root navigator). Test `test/screens/developer_panel_test.dart`.

- Sections: Score override (slider 0–100 + Clear, live mood label), Demo data (Seed demo week, Reset all data), Ollama (host field + Save, Test connection → `LIVE` / `MOCK` chip), Stored data (pretty JSON of signals, XP events, baseline, counters; selectable text).
- Game-history Insights rows must show demo game names: `_gameTitle` strips a `demo:` prefix.
- Tests: long-press opens "Developer tools"; dragging/setting slider to 90 makes `cogniPulseProvider` 90 and shows "Thriving"; Clear restores the real score; Seed shows signals in the JSON viewer.

### Task 7: Verify

`flutter analyze` (no new issues vs. 46), `flutter test`, `flutter build apk --debug`.
